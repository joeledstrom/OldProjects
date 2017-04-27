//
//  Backend.h
//  Simple Talk
//
//  Created by Joel Edström on 3/30/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveRoster.h"
#import "AppConfiguration.h"
#import "SharedStatus.h"

@class CoreDataParentManager;

@protocol AppBackendDelegate <NSObject>
- (void)statusChanged;
- (void)authErrorWhileConnecting;   // set new authInfo to get backend to reconnect
@end

typedef enum {
    kChatHistoryStatusUNKNOWN,
    kChatHistoryStatusSearchingForChatFolder,
    kChatHistoryStatusOK
} ChatHistoryStatus;

typedef enum {
    kGoogleTalkStatusWaitingForAuthInfo,
    kGoogleTalkStatusConnecting,
    kGoogleTalkStatusConnected,
    kGoogleTalkStatusWaitingForNetworkReachability,
    kGoogleTalkStatusWaitingReconnectTimeout
} GoogleTalkStatus;

@interface AppBackend : NSObject
@property (nonatomic, readonly) GoogleTalkStatus status;
@property (nonatomic, readonly) ChatHistoryStatus chatHistoryStatus;
@property (nonatomic, readonly) SharedStatus* sharedStatus;
@property (nonatomic, readonly) LiveRoster* liveRoster;
@property (nonatomic, readonly) AppConfiguration* appConfig;

- (void)addDelegate:(id <AppBackendDelegate>)delegate;
- (void)setAuthInfoToAccount:(NSString*)account accessToken:(NSString*)token;  // will cause backend to connect

- (id)initWithParentManager:(CoreDataParentManager*)parentManager;
- (void)onEnterBackground;
- (void)onUserActivation;
- (BOOL)sendMessage:(NSString*)message toBuddy:(LiveRosterBuddy*)buddy;

@end
