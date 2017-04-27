//
//  XMPPMessaging.m
//  GTell
//
//  Created by Joel Edström on 3/26/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "XMPPMessaging.h"
#import "XMLNode+XMPP.h"
#import "Utils.h"


// Example messages

/*
 <message type='chat' id='61D6F7D2283D2EA8_2' to='joel.edstrom@gmail.com' from='tactilesms@gmail.com/gmail.9A8E9211' iconset='classic'>
 <body>åäö</body>
 <met:google-mail-signature xmlns:met='google:metadata'>7Wg1lS9pzZud1FQfkScfPErS61A</met:google-mail-signature>
 <cha:active xmlns:cha='http://jabber.org/protocol/chatstates'></cha:active>
 <nos:x xmlns:nos='google:nosave' value='disabled'></nos:x>
 <arc:record otr='false' xmlns:arc='http://jabber.org/protocol/archive'></arc:record>
 </message>
 */

/*
 <message type='chat' id='A6C7B377' to='joel.edstrom@gmail.com' from='tactilesms@gmail.com'>
 <cha:inactive xmlns:cha='http://jabber.org/protocol/chatstates'>
 </cha:inactive>
 </message>
*/


@implementation XMPPMessage
- (id)initWithFromJid:(NSString*)from body:(NSString*)body incoming:(BOOL)incoming
{
    self = [super init];
    if (self) {
        _fromJid = from;
        _body = body;
        _incoming = incoming;
    }
    return self;
}
@end


@implementation XMPPMessaging {
    XMPPStreamRemote* _remote;
    __weak id <XMPPMessagingDelegate> _delegate;
    BOOL _streamReadyToSend;
    NSMutableArray* _sendQueue;
}

- (id)initWithDelegate:(id <XMPPMessagingDelegate>)delegate {
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
        [self sendAllQueuedMessages];
    }
}

- (void)messageReceived:(XMLNode *)msg {
    if ([msg.type isEqual:@"chat"] && msg.from) {
        NSString* body = [msg childWithName:@"body"].text;
        if (body) {
            XMPPMessage* message = [[XMPPMessage alloc] initWithFromJid:msg.from body:body incoming:YES];
            
            dispatch_async(_remote.delegateQueue, ^{
                [_delegate messageReceived:message];
            });
        }
    }
}

- (void)sendAllQueuedMessages {
    for (NSString* msg in _sendQueue) {
        [_remote sendData:msg];
    }
}

- (void)sendMessageWithBody:(NSString*)body toJid:(NSString*)to {
    dispatch_async(_remote.xmppQueue, ^{
        static NSString* const baseMsg = @"<message type='chat' to='%@'><body>%@</body></message>";
        
        NSString* msg = [NSString stringWithFormat:baseMsg, to.xmlEscapesEncode, body.xmlEscapesEncode];
        
        if (_streamReadyToSend)
            [_remote sendData:msg];
        else {
            if (!_sendQueue)
                _sendQueue = [NSMutableArray new];
            [_sendQueue addObject:msg];
        }

    });
}
@end
