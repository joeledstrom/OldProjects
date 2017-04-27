//
//  MasterViewController.h
//  GTell
//
//  Created by Joel Edström on 3/3/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;

@end
