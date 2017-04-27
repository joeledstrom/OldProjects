//
//  AppDelegate.m
//  GTell
//
//  Created by Joel Edström on 3/3/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "AppDelegate.h"

#import "ChatPagerVC.h"


#import <CoreData/CoreData.h>
#import "CoreDataParentManager.h"
#import "RosterVC.h"
#import "AppBackend.h"
#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@interface AppDelegate()
@property (nonatomic) CoreDataParentManager* parentManager;
@property (nonatomic) AppBackend* appBackend;
@end

@implementation AppDelegate {
    UIBackgroundTaskIdentifier _backgroundID;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    DDLogVerbose(@"applicationDidReceiveMemoryWarning");
}

- (void)setupIphone {
    RosterVC *roster = [[RosterVC alloc] initWithNibName:@"Roster" bundle:nil];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:roster];
    self.window.rootViewController = self.navigationController;
}

- (void)setupIpad {
    
    
    RosterVC *roster = [[RosterVC alloc] initWithNibName:@"Roster" bundle:nil];
    UINavigationController *rosterNav = [[UINavigationController alloc] initWithRootViewController:roster];
    
    ChatPagerVC *pager = [[ChatPagerVC alloc] initWithNibName:@"ChatPager" bundle:nil];
    UINavigationController *pagerNav = [[UINavigationController alloc] initWithRootViewController:pager];
    
    roster.chatPager = pager;
    //masterViewController.detailViewController = pager;
    
    self.splitViewController = [[UISplitViewController alloc] init];
    self.splitViewController.viewControllers = @[rosterNav, pagerNav];
    self.splitViewController.delegate = pager;
    
    
    
    self.window.rootViewController = self.splitViewController;
}



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Cache" withExtension:@"momd"];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Cache.sqlite"];
    self.parentManager = [[CoreDataParentManager alloc] initWithObjectModel:modelURL store:storeURL];
    
    self.appBackend = [[AppBackend alloc] initWithParentManager:self.parentManager];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
        [self setupIphone];
    else 
        [self setupIpad];
    
    [self.window makeKeyAndVisible];
    
    __block void (^func)() = ^ {
        double delayInSeconds = 15.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.parentManager asyncSave];
            func();
        });
    };
    
    func();
       
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"applicationWillResignActive:");
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [self.parentManager saveContextSync];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"applicationDidEnterBackground:");
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if (_backgroundID) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundID];
    }
    _backgroundID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundID];
    }];
    [self.parentManager asyncSave];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"applicationWillEnterForeground:");
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"applicationDidBecomeActive:");
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"applicationWillTerminate:");
    // Saves changes in the application's managed object context before the application terminates.
    [self.parentManager asyncSave];
}



#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
