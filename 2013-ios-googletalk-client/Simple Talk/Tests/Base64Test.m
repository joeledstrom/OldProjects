//
//  Tests.m
//  Tests
//
//  Created by Joel Edström on 3/18/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "Base64Test.h"
#import "Base64.h"

@implementation Base64Test



- (void)testInverse
{
    NSString* randomString = [NSUUID new].UUIDString;
    
    STAssertEqualObjects(randomString,
                         [NSString fromBase64:randomString.toBase64],
                         @"fromBase64 is the inverse of toBase64");
    
}

@end
