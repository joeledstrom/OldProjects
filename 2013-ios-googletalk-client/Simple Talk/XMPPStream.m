//
//  XMPPStream.m
//  GTell
//
//  Created by Joel Edström on 3/16/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "XMPPStream.h"
#import "XMPPParser.h"
#import "JESocket.h"
#import "XMLNode+XMPP.h"
#import "Base64.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

NSString* const kModuleEventAuthenticationComplete = @"kModuleEventAuthenticationComplete";
NSString* const kModuleEventAuthenticationFailure = @"kModuleEventAuthenticationFailure";
NSString* const kModuleEventStreamDisconnected = @"kModuleEventStreamDisconnected";

@interface XMPPStream() <XMPPParserDelegate, JESocketDelegate>
- (void)sendData:(NSString*)data;
- (void)sendModuleEvent:(NSString*)event;
- (dispatch_queue_t)xmppQueue;
- (dispatch_queue_t)delegateQueue;

- (void)startTLS;
- (void)newStream;
@end

@implementation XMPPStreamRemote {
    __weak XMPPStream* _stream;
}
- (id)initWithStream:(XMPPStream*)stream {
    self = [super init];
    if (self) {
        _stream = stream;
    }
    return self;
}
- (void)sendData:(NSString*)data {
    [_stream sendData:data];
}
- (void)sendModuleEvent:(NSString*)event {
    [_stream sendModuleEvent:event];
}
- (dispatch_queue_t)xmppQueue {
    return _stream.xmppQueue;
}
- (dispatch_queue_t)delegateQueue {
    return _stream.delegateQueue;
}

- (void)startTLS {
    [_stream startTLS];
}
- (void)newStream {
    [_stream newStream];
}
@end



@implementation XMPPStream {
    dispatch_queue_t                    _xmppQueue;
    dispatch_queue_t                    _delegateQueue;
    JESocket*                           _socket;
    XMPPParser*                         _parser;
    NSString*                           _host;
    u_int32_t                           _port;
    __weak id <XMPPStreamDelegate>      _delegate;
    BOOL                                _connectCalled;
    BOOL                                _streamDisconnectedFired;
}

- (id)initWithDelegate:(id <XMPPStreamDelegate>)delegate
         delegateQueue:(dispatch_queue_t)queue
                  host:(NSString*)host
                  port:(u_int32_t)port {
    
    self = [super init];
    if (self) {
        _xmppQueue = dispatch_queue_create("xmppQueue", NULL);
        _delegate = delegate;
        _delegateQueue = queue;
        _host = host;
        _port = port;
    }
    return self;
}

- (void)connect {
    dispatch_async(_xmppQueue, ^{
        NSAssert(_connectCalled == NO, @"not allowed to call connect twice");
        
        [self recreateParser];
        
        _socket = [[JESocket alloc] initWithDelegate:self
                                       delegateQueue:_xmppQueue
                                           connectTo:_host
                                                port:_port
                                                 ssl:NO];
        
        for (id <XMPPModule> m in _modules) {
            [m startWithRemote:[[XMPPStreamRemote alloc] initWithStream:self]];
        }
        _connectCalled = YES;
    });
    
}

- (void)recreateParser {
    [_parser abort];
    _parser = [[XMPPParser alloc] initWithDelegate:self delegateQueue:_xmppQueue];    
}

// return how many bytes consumed, remaining data will be queued up for next callback
- (NSUInteger)consumeData:(NSData*)data {
    //DDLogVerbose(@"RAW DATA: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    [_parser parseData:data];
    return data.length;
}

- (void)socketError:(NSError*)error {
    DDLogVerbose(@"socket error %@", error);
    [_parser abort];
    if (!_streamDisconnectedFired) {
        
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, _xmppQueue, ^(void) {
            if (!_streamDisconnectedFired) {
                _streamDisconnectedFired = YES;
                [self sendModuleEvent:kModuleEventStreamDisconnected];
            }
        });
    }
}

- (void)foundEnd:(NSError *)error {
    DDLogVerbose(@"found end %@", error);
    if (!_streamDisconnectedFired) {
        _streamDisconnectedFired = YES;
        
        [self sendModuleEvent:kModuleEventStreamDisconnected];

    }
}

- (void)foundRoot {
    DDLogVerbose(@"found root \n%@", _parser.root);
}
- (void)foundStanza:(XMLNode*)node {
    DDLogInfo(@"found stanza \n%@", node);

    for (id <XMPPModule> m in _modules) {
        if ([m respondsToSelector:@selector(stanzaReceived:)])
            [m stanzaReceived:node];
            
        
        if ([node.name isEqual:@"message"] && [m respondsToSelector:@selector(messageReceived:)])
            [m messageReceived:node];
        
        if ([node.name isEqual:@"iq"] && [m respondsToSelector:@selector(iqReceived:)])
            [m iqReceived:node];
        
        if ([node.name isEqual:@"presence"] && [m respondsToSelector:@selector(presenceReceived:)])
            [m presenceReceived:node];
    }
}


#pragma mark - Remote methods
- (void)sendData:(NSString*)data {
    [_socket sendData:[data dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)sendModuleEvent:(NSString*)event {
    DDLogInfo(@"Sending module event: %@", event);
    for (id <XMPPModule> m in _modules) {
        if ([m respondsToSelector:@selector(moduleEventRecevied:)])
            [m moduleEventRecevied:event];
    }
    dispatch_async(_delegateQueue, ^{
        [_delegate moduleEventRecevied:event];
    });
}

- (void)startTLS {
    [_socket startTLS];
}
- (void)newStream {
    [self recreateParser];
}
- (dispatch_queue_t)delegateQueue {
    return _delegateQueue;
}
- (dispatch_queue_t)xmppQueue {
    return _xmppQueue;
}

@end
