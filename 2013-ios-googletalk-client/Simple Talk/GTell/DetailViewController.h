//
//  DetailViewController.h
//  GTell
//
//  Created by Joel Edström on 3/3/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
