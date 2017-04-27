//
//  MessageStore.h
//  Simple Talk
//
//  Created by Joel Edström on 3/30/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MessageStoreDelegate <NSObject>



@end

@interface MessageStore : NSObject 
- (id)initWithManagedContext:(NSManagedObjectContext*)moc backendQueue:(dispatch_queue_t)queue;
- (void)setAuthInfoToAccount:(NSString*)account accessToken:(NSString*)token;
- (void)setOlderMessagesNeeded:(BOOL)olderMessagesNeeded;   // set by UI during a search or when scrolling up.
@end
