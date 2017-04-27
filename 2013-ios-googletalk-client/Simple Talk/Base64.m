//
//  Base64.m
//  GTell
//
//  Created by Joel Edström on 3/16/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "Base64.h"

@implementation NSString(Base64)

- (NSString*)toBase64 {
    NSData *plist = [NSPropertyListSerialization dataWithPropertyList:[self dataUsingEncoding:NSASCIIStringEncoding]
                                                               format:NSPropertyListXMLFormat_v1_0
                                                              options:0
                                                                error:NULL];
    if (!plist)
        return nil;
    
    NSString* plistStr = [[NSString alloc] initWithData:plist encoding:NSASCIIStringEncoding];
        
    NSRange r = [plistStr rangeOfString:@"<data>"];
    plistStr = [plistStr stringByReplacingCharactersInRange:NSMakeRange(0, r.location+r.length) withString:@""];
        
    r = [plistStr rangeOfString:@"</data>"];
    plistStr = [plistStr stringByReplacingCharactersInRange:
                NSMakeRange(r.location, plistStr.length-r.location) withString:@""];
    	
	plistStr = [plistStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [plistStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
}
+ (NSString*)fromBase64:(NSString*)base64 {
    
    NSString *plist = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><plist version=\"1.0\"><data>%@</data></plist>", base64];
    
    NSData* d = [NSPropertyListSerialization propertyListWithData:[plist dataUsingEncoding:NSASCIIStringEncoding] options:0 format:NULL error:NULL];
    
    
	return [[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding];
}

- (NSData*)dataFromBase64 {
    
    NSString *plist = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><plist version=\"1.0\"><data>%@</data></plist>", self];
    
    NSData* d = [NSPropertyListSerialization propertyListWithData:[plist dataUsingEncoding:NSASCIIStringEncoding] options:0 format:NULL error:NULL];
    
    
	return d;
}

@end
