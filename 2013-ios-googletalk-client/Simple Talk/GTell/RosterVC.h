//
//  RosterVC.h
//  GTell
//
//  Created by Joel Edström on 3/18/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ChatPagerVC;


@interface RosterVC : UITableViewController
@property (nonatomic) ChatPagerVC* chatPager;
@end
