//
//  LoginVC.m
//  GTell
//
//  Created by Joel Edström on 3/3/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "LoginVC.h"


static NSString* kKeychainItemName = @"GTMOAuth-3";

// TODO: important: hide these!!
static NSString *kMyClientID = @"816202748873.apps.googleusercontent.com";     // pre-assigned by service
static NSString *kMyClientSecret = @"ls8TbIIXypf9ffV4xSgWbhd1"; // pre-assigned by service 

@implementation LoginVC


+ (GTMOAuth2Authentication*)getAuthFromKeyChain {
    GTMOAuth2Authentication *auth;
    auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                 clientID:kMyClientID
                                                             clientSecret:kMyClientSecret];
    
    return auth.canAuthorize ? auth : nil;
    
}


- (id)init {
    return [self initWithNibName:@"LoginView" bundle:nil];
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (IBAction)doLogin {
    
    
    
    NSString *scope = @"https://www.googleapis.com/auth/googletalk https://mail.google.com/";
    
    GTMOAuth2ViewControllerTouch *viewController;

    viewController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:scope
                                                                clientID:kMyClientID
                                                            clientSecret:kMyClientSecret
                                                        keychainItemName:kKeychainItemName
                                                                delegate:self
                                                        finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    viewController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
    if (error != nil) {
        NSLog(@"error");
    } else {
        NSLog(@"accessToken: %@", auth.accessToken);
        NSLog(@"refreshToken: %@", auth.refreshToken);
        
        self.auth = auth;
        [self dismissViewControllerAnimated:YES completion:nil];
        
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8080/register"]];
        
        
        [request setValue:auth.userEmail forHTTPHeaderField:@"username"];
        [request setValue:@"ipad" forHTTPHeaderField:@"deviceToken"];
        [request setValue:auth.accessToken forHTTPHeaderField:@"accessToken"];
        [request setValue:auth.refreshToken forHTTPHeaderField:@"refreshToken"];
        
        
        [request setHTTPMethod:@"POST"];
        
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse  *r, NSData *d, NSError *e)
        {
            if (e == nil) {
                
                NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)r;
                
                NSLog(@"Status Code: %d", httpResponse.statusCode);
                
                for (NSString* key in httpResponse.allHeaderFields.keyEnumerator) {
                    NSString* value = httpResponse.allHeaderFields[key];
                    NSLog(@"%@: %@", key, value);
                }
            }
                                   
        }];
    }
    
}



@end
