//
//  ChatVC.h
//  GTell
//
//  Created by Joel Edström on 3/7/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LiveRosterBuddy;
 
@interface ChatVC : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic,weak) IBOutlet UITableView* tableView;
@property (nonatomic) LiveRosterBuddy* buddy;
@end
