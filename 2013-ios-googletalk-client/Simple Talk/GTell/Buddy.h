//
//  Buddy.h
//  GTell
//
//  Created by Joel Edström on 3/13/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Message;

typedef enum : int32_t {
    kBuddySubscriptionNONE,
    kBuddySubscriptionTO,
    kBuddySubscriptionFROM,
    kBuddySubscriptionBOTH,
} BuddySubscription;

@interface Buddy : NSManagedObject

@property (nonatomic, retain) NSString * jid;
@property (nonatomic) BOOL active;
@property (nonatomic, retain) NSString * name;
@property (nonatomic) BuddySubscription subscription;
@property (nonatomic, retain) NSData * picture;
@property (nonatomic, retain) NSString * pictureHash;
//@property (nonatomic, retain) NSSet *messages;
@end

/*
@interface Buddy (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
*/