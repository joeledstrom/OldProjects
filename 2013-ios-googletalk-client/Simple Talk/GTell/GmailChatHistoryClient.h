//
//  GmailChatHistoryClient.h
//  GTell
//
//  Created by Joel Edström on 3/26/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GmailChatMessage : NSObject
@property (nonatomic, readonly) NSString* toJid;
@property (nonatomic, readonly) NSString* fromJid;
@property (nonatomic, readonly) NSString* body;
@property (nonatomic, readonly) int64_t date;
@property (nonatomic, readonly) int64_t uid;
@end


@interface GmailChatHistoryClient : NSObject
- (id)initWithAccount:(NSString*)account
          accessToken:(NSString*)accessToken
        callbackQueue:(dispatch_queue_t)callbackQueue;

- (void)connect:(void (^)(NSError* error, u_int32_t uidValidityOfChatMailbox))completionHandler;
- (void)fetchMessagesSince:(u_int32_t)uid
                inChucksOf:(NSInteger)chuckSize
              whenFinished:(void (^)(NSError* error, NSArray* messages))completionHandler;
@end
