//
//  GoogleTalkPresence.h
//  GTell
//
//  Created by Joel Edström on 3/18/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPStream.h"


@interface GoogleTalkStatusList : NSObject
@property (nonatomic) NSString* show;
@property (nonatomic) NSArray* statuses;
@end


@interface GoogleTalkSharedStatus : NSObject <XMPPModule>
- (id)initWithAccount:(NSString*)account;
@end
