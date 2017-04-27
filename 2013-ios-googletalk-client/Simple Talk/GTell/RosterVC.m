//
//  RosterVC.m
//  GTell
//
//  Created by Joel Edström on 3/18/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "RosterVC.h"
#import "LoginVC.h"
#import "AppBackend.h"
#import "XMPPRoster.h"
#import "ChatPagerVC.h"
#import "AppDelegate.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;


@interface RosterVC () <AppBackendDelegate, LiveRosterDelegate> @end

@implementation RosterVC {
    GTMOAuth2Authentication* _googleAuth;
    GoogleTalkClient* _talkClient;
    NSArray* _roster;
    UIBarButtonItem* _settingsButton;
    UIPopoverController* _popOver;
    UIBarButtonItem* _statusItem;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
    if (!_googleAuth) {
        _googleAuth = [LoginVC getAuthFromKeyChain];
        
        if (!_googleAuth) {
            
            NSLog(@"didnt get any auth from keychain");
            
            LoginVC* vc = [LoginVC new];
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            
            nav.modalPresentationStyle = UIModalPresentationFormSheet;
            
            
            
            
            
            [self presentViewController:nav animated:YES completion:^{
                NSLog(@"auth window closed");
                _googleAuth = vc.auth;
                [self connect];
            }];
            
            
            
        } else {
            [_googleAuth authorizeRequest:nil completionHandler:^(NSError *error) {
                if (error) {
                    
                } else {
                    [self connect];
                }
            }];
            
        }
    }
}
- (void)authErrorWhileConnecting {
    
}

- (void)statusChanged {
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    switch (appDelegate.appBackend.status) {
        case kGoogleTalkStatusWaitingForAuthInfo:
            _statusItem.title = @"WaitingForAuthInfo";
            break;
        case kGoogleTalkStatusConnecting:
            _statusItem.title = @"Connecting";
            break;
        case kGoogleTalkStatusConnected:
            _statusItem.title = @"Connected";
            break;
        case kGoogleTalkStatusWaitingForNetworkReachability:
            _statusItem.title = @"WaitingForNetworkReachability";
            break;
        case kGoogleTalkStatusWaitingReconnectTimeout:
            _statusItem.title = @"WaitingReconnectTimeout";
            break;
    }
}

- (void)connect {
    
    //return;
    
    NSLog(@"trying to connect: %@, %@", _googleAuth.userEmail, _googleAuth.accessToken);
    
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate.appBackend setAuthInfoToAccount:_googleAuth.userEmail accessToken:_googleAuth.accessToken];
}



- (void)rosterChangedTo:(NSArray*)roster
     addedRowIndexPaths:(NSArray*)added
   changedRowIndexPaths:(NSArray*)changed
 movedRowIndexPathsFrom:(NSArray*)movedFrom toIndexPaths:(NSArray*)movedTo
   removedRowIndexPaths:(NSArray*)removed {
    
    
    DDLogVerbose(@"OLD ROSTER: %@", _roster);
    DDLogVerbose(@"added: %@, changed: %@, movedFrom: %@, movedTo: %@, removed: %@", added, changed, movedFrom, movedTo, removed);
    DDLogVerbose(@"NEW ROSTER: %@", roster);
    
    for (LiveRosterBuddy* b in roster) {
        //DDLogInfo(@"%@: %f, %f", b.jid, b.picture.size.width, b.picture.size.height);
    }
    
    [self.tableView beginUpdates];
    
    _roster = roster;

    [self.tableView insertRowsAtIndexPaths:added withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadRowsAtIndexPaths:changed withRowAnimation:UITableViewRowAnimationNone];

    
    [self.tableView deleteRowsAtIndexPaths:movedFrom withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView insertRowsAtIndexPaths:movedTo withRowAnimation:UITableViewRowAnimationFade];
    
    
    /*[movedFrom enumerateObjectsUsingBlock:^(NSIndexPath* ip, NSUInteger idx, BOOL *stop) {
        [self.tableView moveRowAtIndexPath:ip toIndexPath:movedTo[idx]];
        
        NSIndexPath* toIp = movedTo[idx];
        
        [self fillCell:[self.tableView cellForRowAtIndexPath:toIp] forIndexPath:toIp];
    }];*/
    
    [self.tableView deleteRowsAtIndexPaths:removed withRowAnimation:UITableViewRowAnimationAutomatic];
   
    [self.tableView endUpdates];
    
}
- (void)kaka {
    UIStoryboard* settings = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
    UIViewController* settingsVC = [settings instantiateInitialViewController];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:settingsVC animated:YES];
    } else {
        
        if (_popOver) {
            [_popOver dismissPopoverAnimated:YES];
            _popOver = nil;
        } else {
            UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
            _popOver = [[UIPopoverController alloc] initWithContentViewController:nav];
            [_popOver presentPopoverFromBarButtonItem:_settingsButton
                             permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
   
    
    
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    
    [appDelegate.appBackend addDelegate:self];
    [appDelegate.appBackend.liveRoster addDelegate:self];
    
    
    if (!self.chatPager) {
        NSLog(@"shouldbt happen on iPAd");
        self.chatPager = [[ChatPagerVC alloc] initWithNibName:@"ChatPager" bundle:nil];
    }
    
    _settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"\u2699" style:UIBarButtonItemStyleBordered target:self action:@selector(kaka)];
    
    [_settingsButton setTitleTextAttributes:@{UITextAttributeFont: [UIFont fontWithName:@"Helvetica" size:22]}
                         forState:UIControlStateNormal];
    
    
    UIBarButtonItem* add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:nil action:nil];
    
    //
    //self.navigationController.toolbarHidden = NO;
    self.title = @"Contacts";
    
    self.navigationItem.leftBarButtonItem = _settingsButton;
    self.navigationItem.rightBarButtonItem = add;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    
    _statusItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.toolbarItems = @[_statusItem];
    self.navigationController.toolbarHidden = NO;
}


- (void)fillCell:(UITableViewCell*)cell forIndexPath:(NSIndexPath*)ip {
    LiveRosterBuddy* b = _roster[ip.row];
    
    cell.textLabel.text = b.name ?: b.jid;
    cell.detailTextLabel.text = @(b.status).stringValue;
    cell.imageView.image = b.picture;
}

#pragma mark - Table view data source




- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _roster.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    [self fillCell:cell forIndexPath:indexPath];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: iphone navcontroller push
    [self.chatPager openChatForBuddy:_roster[indexPath.row]];
    
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
