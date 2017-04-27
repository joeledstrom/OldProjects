//
//  XMPPStream.h
//  GTell
//
//  Created by Joel Edström on 3/16/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>



@class XMLNode;
@class XMPPStream;


@interface XMPPStreamRemote : NSObject
- (void)sendData:(NSString*)data;
- (dispatch_queue_t)delegateQueue;
- (dispatch_queue_t)xmppQueue;
- (void)sendModuleEvent:(NSString*)event;

// advanced
- (void)startTLS;
- (void)newStream;
@end


@protocol XMPPModule <NSObject>
@required
- (void)startWithRemote:(XMPPStreamRemote*)remote;
@optional
- (void)moduleEventRecevied:(NSString*)event;
- (void)messageReceived:(XMLNode*)msg;
- (void)iqReceived:(XMLNode*)iq;
- (void)presenceReceived:(XMLNode*)presence;
- (void)stanzaReceived:(XMLNode*)stanza;
@end


// authenticator module should emit these:
extern NSString* const kModuleEventAuthenticationComplete;
extern NSString* const kModuleEventAuthenticationFailure;

// XMPPStream will emit these:
extern NSString* const kModuleEventStreamDisconnected;

@protocol XMPPStreamDelegate <NSObject>
- (void)moduleEventRecevied:(NSString*)event;
@end


@interface XMPPStream : NSObject
@property (nonatomic) NSArray* modules;

- (id)initWithDelegate:(id <XMPPStreamDelegate>)delegate
         delegateQueue:(dispatch_queue_t)queue
                  host:(NSString*)host
                  port:(u_int32_t)port;

- (void)connect;
@end
