//
//  Message.h
//  Simple Talk
//
//  Created by Joel Edström on 3/28/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Buddy;

@interface Message : NSManagedObject

@property (nonatomic) int64_t date;
@property (nonatomic) BOOL fromUser;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber* imapUID;
@property (nonatomic, retain) Buddy *buddy;

@end
