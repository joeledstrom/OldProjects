//
//  XMPPRoster2.h
//  Simple Talk
//
//  Created by Joel Edström on 3/31/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMPPStream.h"

@interface XMPPResource2 : NSObject
@property (nonatomic, readonly) NSString* jid;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSInteger priority;
@property (nonatomic, readonly) NSString* show;
@property (nonatomic, readonly) NSString* status;
@end



@interface XMPPBuddy2 : NSObject
@property (nonatomic, readonly) NSString* jid;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSString* subscription;
@end

@protocol XMPPRoster2Delegate <NSObject>
@optional
- (void)setBuddy:(XMPPBuddy2*)buddy;
- (void)removeBuddyWithJid:(NSString*)jid;

- (void)setResource:(XMPPResource2*)resource;
- (void)removeResourceForJid:(NSString*)jid withName:(NSString*)resourceName;
@end

@interface XMPPRoster2 : NSObject <XMPPModule>
- (void)addDelegate:(id <XMPPRoster2Delegate>)delegate;
@end

