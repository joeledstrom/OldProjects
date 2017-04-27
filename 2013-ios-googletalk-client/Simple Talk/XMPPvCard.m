//
//  XMPPvCard.m
//  Simple Talk
//
//  Created by Joel Edström on 3/29/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "XMPPvCard.h"
#import "XMLNode+XMPP.h"
#import "Utils.h"

@implementation XMPPvCard {
    XMPPStreamRemote* _remote;
    __weak id <XMPPvCardDelegate> _delegate;
    BOOL _streamReadyToSend;
    NSMutableArray* _sendQueue;
}

- (id)initWithDelegate:(id <XMPPvCardDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)startWithRemote:(XMPPStreamRemote *)remote {
    _remote = remote;
}
- (void)moduleEventRecevied:(NSString *)event {
    if ([event isEqual:kModuleEventAuthenticationComplete]) {
        _streamReadyToSend = YES;
    }
}


- (void)sendAllQueuedMessages {
    for (NSString* fetchReq in _sendQueue) {
        [_remote sendData:fetchReq];
    }
}

- (void)fetchVCardForJid:(NSString*)jid; {
    dispatch_async(_remote.xmppQueue, ^{
        static NSString* const baseMsg = @"<iq to='%@' type='get'><vCard xmlns='vcard-temp'/></iq>";
        
        NSString* msg = [NSString stringWithFormat:baseMsg, jid];
        
        if (_streamReadyToSend)
            [_remote sendData:msg];
        else {
            if (!_sendQueue)
                _sendQueue = [NSMutableArray new];
            [_sendQueue addObject:msg];
        }
        
    });
}

- (void)iqReceived:(XMLNode*)iq {
    XMLNode* vCard = [iq childWithName:@"vCard"];
    if ([iq.type isEqual:@"result"] && [vCard.attributes[@"xmlns"] isEqual:@"vcard-temp"] && iq.from) {
        NSString* from = [iq.from bareJid];
        
        
        dispatch_async(_remote.delegateQueue, ^{
            [_delegate receivedVcard:vCard forJid:from];
        });
    }
}

- (void)presenceReceived:(XMLNode*)presence {
    
    XMLNode* x = [[presence childrenWithName:@"x"] filter:^BOOL(XMLNode* c) {
        return [c.attributes[@"xmlns"] isEqual:@"vcard-temp:x:update"];
    }].first;
    
    
    if (x && presence.from) {
        XMLNode* photo = [x childWithName:@"photo"];
        if (photo) {
            NSString* hash = photo.text;
            dispatch_async(_remote.delegateQueue, ^{
                [_delegate vCardUpdateForJid:presence.from.bareJid receviedWithHash:hash];
            });
        }
    }
        
}

@end




