//
//  ChatPagerVC.h
//  GTell
//
//  Created by Joel Edström on 3/7/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GoogleTalkClient;
@class LiveRosterBuddy;

@interface ChatPagerVC : UIViewController
    <UISplitViewControllerDelegate,
    UIPageViewControllerDelegate,
    UIPageViewControllerDataSource, UITextViewDelegate>

@property UIPageViewController* pageViewController;
@property (nonatomic,weak) IBOutlet UIView* topBar;
@property (nonatomic,weak) IBOutlet UIPageControl* pageControl;
@property (nonatomic,weak) IBOutlet UIView* pageControllerContainer;
@property (nonatomic,weak) IBOutlet UITextView* chatBox;
@property (nonatomic,weak) IBOutlet NSLayoutConstraint* keyboardSpacer;
- (void)openChatForBuddy:(LiveRosterBuddy*)buddy;
//- (IBAction)sendMessage:(id)sender;
@end
