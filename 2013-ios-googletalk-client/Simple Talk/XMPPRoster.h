//
//  XMPPRoster.h
//  GTell
//
//  Created by Joel Edström on 3/21/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "XMPPStream.h"

@interface XMPPResource : NSObject
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSInteger priority;
@end

typedef enum : NSInteger {
    XMPPSubscriptionUNDEFINED = -1,
    XMPPSubscriptionNONE,
    XMPPSubscriptionTO,
    XMPPSubscriptionFROM,
    XMPPSubscriptionBOTH,
    XMPPSubscriptionREMOVE
} XMPPSubscription;

/*
typedef enum : NSInteger {
    XMPPPresenceShowUNAVAILABLE,
    XMPPPresenceShowAVAILABLE,
    XMPPPresenceShowAWAY,
} XMPPPresenceShow;
*/

@interface XMPPBuddy : NSObject
@property (nonatomic, readonly) NSString* jid;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSDictionary* resources;
@property (nonatomic, readonly) XMPPSubscription subscription;
@property (nonatomic, readonly) NSString* show;
@property (nonatomic, readonly) NSString* status;
@end

@protocol XMPPRosterDelegate <NSObject>
- (void)rosterChangedTo:(NSDictionary*)roster
              addedJids:(NSArray*)added
            changedJids:(NSArray*)changed
            removedJids:(NSArray*)removed;
@end

@interface XMPPRoster : NSObject <XMPPModule>
- (id)initWithDelegate:(id <XMPPRosterDelegate>)delegate;
@end
