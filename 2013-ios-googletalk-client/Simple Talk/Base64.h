//
//  Base64.h
//  GTell
//
//  Created by Joel Edström on 3/16/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface NSString(Base64)
- (NSString*)toBase64;
+ (NSString*)fromBase64:(NSString*)base64;
- (NSData*)dataFromBase64;
@end
