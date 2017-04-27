//
//  AppDelegate.h
//  GTell
//
//  Created by Joel Edström on 3/3/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppBackend.h"
#import "CoreDataParentManager.h"



@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow* window;
@property (strong, nonatomic) UINavigationController* navigationController;
@property (strong, nonatomic) UISplitViewController* splitViewController;
@property (readonly, nonatomic) CoreDataParentManager* parentManager;
@property (readonly, nonatomic) AppBackend* appBackend;


- (NSURL *)applicationDocumentsDirectory;

@end
