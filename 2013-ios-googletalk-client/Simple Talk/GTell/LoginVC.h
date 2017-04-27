//
//  LoginVC.h
//  GTell
//
//  Created by Joel Edström on 3/3/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTMOAuth2ViewControllerTouch.h"


@interface LoginVC : UIViewController
@property (nonatomic) GTMOAuth2Authentication* auth;
+ (GTMOAuth2Authentication*)getAuthFromKeyChain;

- (IBAction)doLogin;
@end
