//
//  XMPPMessaging.h
//  GTell
//
//  Created by Joel Edström on 3/26/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPStream.h"

@interface XMPPMessage : NSObject
@property (nonatomic, readonly) NSString* fromJid;
@property (nonatomic, readonly) NSString* body;
@property (nonatomic, readonly) BOOL incoming;
- (id)initWithFromJid:(NSString*)from body:(NSString*)body incoming:(BOOL)incoming;
@end

@protocol XMPPMessagingDelegate <NSObject>

- (void)messageReceived:(XMPPMessage*)message;

@end

@interface XMPPMessaging : NSObject <XMPPModule>
- (id)initWithDelegate:(id <XMPPMessagingDelegate>)delegate;
- (void)sendMessageWithBody:(NSString*)body toJid:(NSString*)to;
@end
