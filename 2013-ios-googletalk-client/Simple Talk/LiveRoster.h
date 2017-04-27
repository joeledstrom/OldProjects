//
//  LiveRoster.h
//  Simple Talk
//
//  Created by Joel Edström on 3/30/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPRoster2.h"



typedef enum {
    kLiveRosterBuddyStatusOFFLINE,
    kLiveRosterBuddyStatusDND,
    kLiveRosterBuddyStatusIDLE,
    kLiveRosterBuddyStatusAVAILABLE
} LiveRosterBuddyStatus;

@interface LiveRosterBuddy : NSObject
@property (nonatomic, readonly) NSString* jid;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) UIImage* picture;
@property (nonatomic, readonly) NSString* statusText;
@property (nonatomic, readonly) LiveRosterBuddyStatus status;
@end


@protocol LiveRosterDelegate <NSObject>
- (void)rosterChangedTo:(NSArray*)roster
     addedRowIndexPaths:(NSArray*)added
   changedRowIndexPaths:(NSArray*)changed
 movedRowIndexPathsFrom:(NSArray*)movedFrom toIndexPaths:(NSArray*)movedTo
   removedRowIndexPaths:(NSArray*)removed;
@end
@interface LiveRoster : NSObject <XMPPRoster2Delegate>
- (void)addDelegate:(id <LiveRosterDelegate>)delegate;
- (id)initWithManagedContext:(NSManagedObjectContext*)moc backendQueue:(dispatch_queue_t)queue;
@end
