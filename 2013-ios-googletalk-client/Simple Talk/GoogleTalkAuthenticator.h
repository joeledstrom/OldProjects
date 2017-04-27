//
//  GoogleTalkAuthenticator.h
//  GTell
//
//  Created by Joel Edström on 3/18/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "XMPPStream.h"

@interface GoogleTalkAuthenticator : NSObject <XMPPModule>
- (id)initWithAccount:(NSString*)account
          accessToken:(NSString*)accessToken;
@end
