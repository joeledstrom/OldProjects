//
//  XMPPRoster.m
//  GTell
//
//  Created by Joel Edström on 3/21/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "XMPPRoster2.h"
#import "XMPPParser.h"
#import "XMLNode+XMPP.h"
#import "Utils.h"
#import "MulticastDelegate.h"



@implementation XMPPResource2
- (id)initWithJid:(NSString*)jid
             name:(NSString*)name
         priority:(NSInteger)priority
             show:(NSString*)show
           status:(NSString*)status;
{
    self = [super init];
    if (self) {
        _jid = jid;
        _name = name;
        _priority = priority;
        _show = show;
        _status = status;
    }
    return self;
}
@end

@implementation XMPPBuddy2
- (id)initWithJid:(NSString*)jid
             name:(NSString*)name
     subscription:(NSString*)subscription
             
{
    self = [super init];
    if (self) {
        _jid = jid;
        _name = name;
        _subscription = subscription;
    }
    return self;
}
@end



@implementation XMPPRoster2 {
    XMPPStreamRemote* _remote;
    MulticastDelegate* _delegates;
}
- (id)init
{
    self = [super init];
    if (self) {
        _delegates = [MulticastDelegate new];
    }
    return self;
}
- (void)addDelegate:(id<XMPPRoster2Delegate>)delegate {
    [_delegates addDelegate:delegate];
}

- (void)startWithRemote:(XMPPStreamRemote*)remote {
    _remote = remote;
}
- (void)moduleEventRecevied:(NSString *)event {
    static NSString* rosterRequest = @"<iq type='get' id='roster_1'><query xmlns='jabber:iq:roster'/></iq>";
    
    if ([event isEqual:kModuleEventAuthenticationComplete]) {
        [_remote sendData:rosterRequest];
    }
    
}
- (void)presenceReceived:(XMLNode*)presence {
    if ([presence.type isEqual: @"unavailable"]) {
        NSString* fromJid = presence.attributes[@"from"];
        
        [_delegates iterateDelegatesOnQueue:_remote.delegateQueue withBlock:^(id<XMPPRoster2Delegate> delegate) {
            if ([delegate respondsToSelector:@selector(removeResourceForJid:withName:)])
                [delegate removeResourceForJid:fromJid.bareJid withName:fromJid.jidResource];
        }];
    }
    if (presence.type == nil) {
        NSString* fromJid = presence.attributes[@"from"];
        NSString* show = [presence childWithName:@"show"].text ?: @"";
        NSString* status = [presence childWithName:@"status"].text ?: @"";
        
        NSString* bare = fromJid.bareJid;
        NSString* resource = fromJid.jidResource;
        NSInteger priority = [presence childWithName:@"priority"].text.integerValue;
        
        XMPPResource2* res = [[XMPPResource2 alloc] initWithJid:bare name:resource priority:priority show:show status:status];
        
        [_delegates iterateDelegatesOnQueue:_remote.delegateQueue withBlock:^(id<XMPPRoster2Delegate> delegate) {
            if ([delegate respondsToSelector:@selector(setResource:)])
                [delegate setResource:res];
        }];
    }
}

- (void)iqReceived:(XMLNode*)iq {
    if ([iq.type isEqual:@"result"] || [iq.type isEqual:@"set"]) {
        XMLNode* query = [iq childWithName:@"query"];
        if ([query.attributes[@"xmlns"] isEqual:@"jabber:iq:roster"]) {
            
            for (XMLNode* x in [query childrenWithName:@"item"]) {
                NSString* sub = x.attributes[@"subscription"] ?: @"none";
                NSString* name = x.attributes[@"name"];
                
                BOOL remove = NO;
                
                if ([sub isEqual:@"remove"]) {
                    remove = YES;
                }
                
                NSString* jid = x.attributes[@"jid"];
                
                if (!jid)
                    continue;
                
                XMPPBuddy2* b = [[XMPPBuddy2 alloc] initWithJid:jid.bareJid name:name subscription:sub];
                
                
                [_delegates iterateDelegatesOnQueue:_remote.delegateQueue withBlock:^(id<XMPPRoster2Delegate> delegate) {
                    if (remove && [delegate respondsToSelector:@selector(removeBuddyWithJid:)])
                        [delegate removeBuddyWithJid:jid];
                    else if ([delegate respondsToSelector:@selector(setBuddy:)])
                        [delegate setBuddy:b];
                }];
            }
        }
    }
    
}

@end


