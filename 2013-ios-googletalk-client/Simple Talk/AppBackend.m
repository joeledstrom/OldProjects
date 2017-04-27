//
//  Backend.m
//  Simple Talk
//
//  Created by Joel Edström on 3/30/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "AppBackend.h"
#import "RosterStore.h"
#import "MessageStore.h"
#import "CoreDataParentManager.h"
#import "XMPPMessaging.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#import "DDLog.h"
#import "GoogleTalkAuthenticator.h"
#import "XMPPRoster2.h"
#import "GoogleTalkSharedStatus.h"
#import "XMPPvCard.h"
#import "MulticastDelegate.h"
#import "LiveRoster.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;
static NSString* const talkHostname = @"talk.google.com";


@interface MessageStore () <XMPPMessagingDelegate>
- (void)onUserActivation;
- (void)addLocalMessage:(XMPPMessage*)msg;

@end



void networkReachabilityChanged(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info);

@interface AppBackend () <XMPPStreamDelegate>
@property (nonatomic) GoogleTalkStatus status;
@end
@implementation AppBackend {
    MulticastDelegate* _delegates;
    RosterStore* _rosterStore;
    MessageStore* _messageStore;
    dispatch_queue_t _backendQueue;
    NSManagedObjectContext* _backendMOC;
    NSString* _account;
    NSString* _accessToken;
    XMPPStream* _xmppStream;
    XMPPMessaging* _messaging;
    double _reconnectTimeout;
}
- (void)addDelegate:(id <AppBackendDelegate>)delegate {
    [_delegates addDelegate:delegate];
}

- (void)changeStatus:(GoogleTalkStatus)newStatus {
    
    // change from state:
    GoogleTalkStatus oldStatus = self.status;
    
    if (oldStatus == newStatus)
        return;
    
    switch (oldStatus) {
        case kGoogleTalkStatusWaitingForAuthInfo:
            if (newStatus == kGoogleTalkStatusWaitingReconnectTimeout)
                return;
            break;
        case kGoogleTalkStatusConnecting:
            if (newStatus != kGoogleTalkStatusConnected) {
                [_rosterStore setXMPPvCard:nil];
                _xmppStream = nil;
            }
            break;
        case kGoogleTalkStatusConnected:
            [_rosterStore setXMPPvCard:nil];
            _xmppStream = nil;
            break;
        
        case kGoogleTalkStatusWaitingForNetworkReachability:
            if (newStatus == kGoogleTalkStatusWaitingReconnectTimeout)
                return;
            break;
        case kGoogleTalkStatusWaitingReconnectTimeout:
            
            break;
    }
    
    self.status = newStatus;
    
    
    // to state:
    
    switch (newStatus) {
        case kGoogleTalkStatusWaitingForAuthInfo:
            
            [_delegates iterateDelegatesOnQueue:dispatch_get_main_queue()
                                      withBlock:^(id<AppBackendDelegate> delegate) {
                                          [delegate authErrorWhileConnecting]; }];
            
            break;
            
        case kGoogleTalkStatusConnecting:
            [self connect];
            break;
        case kGoogleTalkStatusConnected:
            [_messageStore setAuthInfoToAccount:_account accessToken:_accessToken];
            _reconnectTimeout = 5;  // reset
            break;
            
        case kGoogleTalkStatusWaitingForNetworkReachability:
            
            break;
        case kGoogleTalkStatusWaitingReconnectTimeout:
            
            DDLogVerbose(@"Reconnecting in %f seconds...", _reconnectTimeout);
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_reconnectTimeout * NSEC_PER_SEC));
            dispatch_after(popTime, _backendQueue, ^{
                DDLogVerbose(@"   reconnecting");
                [self changeStatus:kGoogleTalkStatusConnecting];
            });
            
            _reconnectTimeout = _reconnectTimeout * 1.5;
            
            break;
    }
    
    DDLogInfo(@"Transitioned from state %d to %d", oldStatus, self.status);
    
    [self notifyStatusChanged];
}

- (void)onNetworkReachable {
    DDLogVerbose(@"onNetworkReachable");
    if (_status == kGoogleTalkStatusWaitingForNetworkReachability)
        [self changeStatus:kGoogleTalkStatusConnecting];
}

- (void)onNetworkUnreachable {
    DDLogVerbose(@"onNetworkUnreachable");
    [self changeStatus:kGoogleTalkStatusWaitingForNetworkReachability];
}

- (void)setAuthInfoToAccount:(NSString*)account accessToken:(NSString*)token {
    dispatch_async(_backendQueue, ^{
        _account = account;
        _accessToken = token;
        
        SCNetworkReachabilityRef nrRef = SCNetworkReachabilityCreateWithName(NULL, talkHostname.UTF8String);
        SCNetworkReachabilityFlags flags;
        if (!SCNetworkReachabilityGetFlags(nrRef, &flags) || (flags & kSCNetworkFlagsReachable)) {
            DDLogVerbose(@"Network reachable or of unknown status, connecting");
            [self changeStatus:kGoogleTalkStatusConnecting];
        } else {
            [self changeStatus:kGoogleTalkStatusWaitingForNetworkReachability];
        }
    });
    
}

- (void)connect {
    assert(self.status != kGoogleTalkStatusConnected);
    
    
    _xmppStream = [[XMPPStream alloc] initWithDelegate:self
                                         delegateQueue:_backendQueue
                                                  host:talkHostname
                                                  port:5222];
    
    
    
    GoogleTalkAuthenticator* auth = [[GoogleTalkAuthenticator alloc] initWithAccount:_account accessToken:_accessToken];
    XMPPRoster2* roster = [[XMPPRoster2 alloc] init];
    [roster addDelegate:_rosterStore];
    [roster addDelegate:_liveRoster];
    
    GoogleTalkSharedStatus* status = [[GoogleTalkSharedStatus alloc] initWithAccount:_account];
    _messaging = [[XMPPMessaging alloc] initWithDelegate:_messageStore];
    
    XMPPvCard* vCard = [[XMPPvCard alloc] initWithDelegate:_rosterStore];
    [_rosterStore setXMPPvCard:vCard];
    
    _xmppStream.modules = @[auth, roster, status, _messaging, vCard];
    
    
    [_xmppStream connect];
    
    
}

- (void)moduleEventRecevied:(NSString *)event {
    
    if (self.status == kGoogleTalkStatusConnecting) {
        if ([event isEqual:kModuleEventAuthenticationComplete]) {
            
            [self changeStatus:kGoogleTalkStatusConnected];
            
        } else if ([event isEqual:kModuleEventAuthenticationFailure]) {
            
            [self changeStatus:kGoogleTalkStatusWaitingForAuthInfo];
            
        } else if ([event isEqual:kModuleEventStreamDisconnected]) {  // timed out
            
            [self changeStatus:kGoogleTalkStatusWaitingReconnectTimeout];
            
        }
        
        
    } else {
        
        if ([event isEqual:kModuleEventStreamDisconnected]) {
            [self changeStatus:kGoogleTalkStatusWaitingReconnectTimeout];
        }
  
    }
    
    
}



- (void)notifyStatusChanged {
    [_delegates iterateDelegatesOnQueue:dispatch_get_main_queue()
                              withBlock:^(id<AppBackendDelegate> delegate)
    {
        [delegate statusChanged];
    }];
}

- (id)initWithParentManager:(CoreDataParentManager*)parentManager
{
    self = [super init];
    if (self) {
        
        _status = kGoogleTalkStatusWaitingForAuthInfo;
        _reconnectTimeout = 5;
        
        _backendQueue = dispatch_queue_create("AppBackendQueue", NULL);
        _backendMOC = parentManager.getChildContext;
        
        _rosterStore = [[RosterStore alloc] initWithManagedContext:_backendMOC backendQueue:_backendQueue];
        _messageStore = [[MessageStore alloc] initWithManagedContext:_backendMOC backendQueue:_backendQueue];
        _liveRoster = [[LiveRoster alloc] initWithManagedContext:_backendMOC backendQueue:_backendQueue];

        _delegates = [MulticastDelegate new];
        
        SCNetworkReachabilityRef nrRef = SCNetworkReachabilityCreateWithName(NULL, talkHostname.UTF8String);
        SCNetworkReachabilityContext context;
        memset(&context, 0, sizeof(SCNetworkReachabilityContext));
        context.info = (__bridge SCNetworkReachabilityContext *)self;
        
        SCNetworkReachabilitySetCallback(nrRef, networkReachabilityChanged, &context);
        SCNetworkReachabilitySetDispatchQueue(nrRef, _backendQueue);
        CFRelease(nrRef);
    }
    return self;
}

- (void)onEnterBackground {
    dispatch_async(_backendQueue, ^{
        [self.sharedStatus setIdle]; // TODO: delay 2-3 min
    });
    
}
- (void)onUserActivation {
    dispatch_async(_backendQueue, ^{
        [self.sharedStatus setActive]; 
    });
}

- (BOOL)sendMessage:(NSString*)message toBuddy:(LiveRosterBuddy*)buddy {
    if (self.status != kGoogleTalkStatusConnected)
        return NO;
    
    dispatch_async(_backendQueue, ^{
        [_messageStore addLocalMessage:[[XMPPMessage alloc] initWithFromJid:buddy.jid body:message incoming:NO]];
        [_messaging sendMessageWithBody:message toJid:buddy.jid];
    });
    
    return self.status == kGoogleTalkStatusConnected;
}


@end

void networkReachabilityChanged(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    AppBackend* appBackend = (__bridge AppBackend *)info;
    
    if (flags & kSCNetworkReachabilityFlagsReachable) {
        [appBackend onNetworkReachable];
    } else {
        [appBackend onNetworkUnreachable];
    }
}
