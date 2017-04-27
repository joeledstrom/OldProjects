//
//  ChatPagerVC.m
//  GTell
//
//  Created by Joel Edström on 3/7/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "ChatPagerVC.h"
#import "ChatVC.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "Message.h"
#import "Utils.h"
#import "AppBackend.h"


@interface ChatPagerVC () @end

@implementation ChatPagerVC {
    NSMutableArray* _pages;
}

- (void)openChatForBuddy:(LiveRosterBuddy*)buddy {
    
    ChatVC* chatVC = [[[_pages subarrayWithRange:NSMakeRange(1, _pages.count-1)] filter:^BOOL(ChatVC* c) {
        return [c.buddy.jid isEqual: buddy.jid];
    }] first];
    
    if (!chatVC) {
        self.pageControl.numberOfPages++;
        chatVC = [[ChatVC alloc] initWithNibName:@"ChatVC" bundle:nil];
        chatVC.buddy = buddy;
        [_pages addObject:chatVC];
    }
    [self.pageViewController setViewControllers:@[chatVC]
                  direction:UIPageViewControllerNavigationDirectionForward
                   animated:YES
                 completion:nil];
    
    [self updatePageControl];
    
    
}

- (void)textViewDidChange:(UITextView *)textView {
    [self.chatBox invalidateIntrinsicContentSize];
    [self.chatBox scrollRectToVisible:(CGRect) {CGPointZero, self.chatBox.contentSize} animated:NO];
    //NSLog(@"%f", self.chatBox.bounds.size.height);  // chose 106 for 5 lines
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if ([text isEqual:@"\n"]) {
        ChatVC* cvc = self.pageViewController.viewControllers[0];
        
        AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
        if ([appDelegate.appBackend sendMessage:textView.text toBuddy:cvc.buddy])
            textView.text = @"";
        
        return NO;
    } else {
        return YES;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self.chatBox invalidateIntrinsicContentSize];
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)b
{
    self = [super initWithNibName:nibNameOrNil bundle:b];
    if (self) {
        _pages = [NSMutableArray new];
        [_pages addObject:[[UIViewController alloc] initWithNibName:@"EmptyPager" bundle:nil]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    
    self.chatBox.delegate = self;
    self.chatBox.text = @"";
    
    
    
    self.pageControl.numberOfPages = 1;
    
    
    /*self.pageControl.superview.layer.shadowOpacity = 0.5;
    self.pageControl.superview.layer.shadowOffset = CGSizeMake(0, 3);
    self.chatBox.superview.layer.shadowOpacity = 0.5;
    self.chatBox.superview.layer.shadowOffset = CGSizeMake(0, -3);*/
    
    
    
    self.pageViewController = [[UIPageViewController alloc]
       initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
         navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                        options:@{UIPageViewControllerOptionInterPageSpacingKey: @20}];
    
    UIPageViewController* pvc = self.pageViewController;
    
    pvc.delegate = self;
    pvc.dataSource = self;
    
       
    [pvc setViewControllers:@[_pages[0]]
                  direction:UIPageViewControllerNavigationDirectionForward
                   animated:YES
                 completion:nil];
    
    [self addChildViewController:pvc];
    
    pvc.view.frame = self.pageControllerContainer.bounds;
    
    [self.pageControllerContainer addSubview:pvc.view];

    [pvc didMoveToParentViewController:self];
    

    [self.view bringSubviewToFront:self.chatBox.superview];
    [self.view bringSubviewToFront:self.pageControl.superview];
}



- (void)viewWillLayoutSubviews {
    //[self.pageViewController.view setNeedsLayout];
}


- (void)keyboardWillShow:(NSNotification *)n {
    NSLog(@"willShow %@", n.userInfo[UIKeyboardFrameEndUserInfoKey]);
    CGRect kFrame = [n.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval dur = [n.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    BOOL portrait = UIDeviceOrientationIsPortrait(self.interfaceOrientation);
    
    self.keyboardSpacer.constant = -(portrait ? kFrame.size.height : kFrame.size.width);
    
    [UIView animateWithDuration:dur animations:^{
        [self.view layoutIfNeeded];
    }];
}


- (void)keyboardWillHide:(NSNotification *)n {
    NSLog(@"willHide %@", n.userInfo[UIKeyboardFrameEndUserInfoKey]);
    NSTimeInterval dur = [n.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    self.keyboardSpacer.constant = 0;
    
    [UIView animateWithDuration:dur animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - UISplitViewControllerDelegate

- (BOOL)splitViewController:(UISplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation {
    return NO;
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {
    NSInteger beforeIndex = [_pages indexOfObject:viewController]-1;
    
    return beforeIndex < 0 ? nil : _pages[beforeIndex];
}
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {
    NSInteger afterIndex = [_pages indexOfObject:viewController]+1;
    
    return afterIndex >= _pages.count ? nil : _pages[afterIndex];
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed {
    
    
    if (finished && completed) {
        [self updatePageControl];
        
    }
}

- (void)updatePageControl {
    self.pageControl.currentPage = [_pages indexOfObject:self.pageViewController.viewControllers[0]];
    UIViewController* c = self.pageViewController.viewControllers[0];
    self.title = c.title;
}


@end
