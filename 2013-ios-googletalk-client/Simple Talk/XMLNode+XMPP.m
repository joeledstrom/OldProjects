//
//  XMLNode+XMPP.m
//  GTell
//
//  Created by Joel Edström on 3/16/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "XMLNode+XMPP.h"
#import "Utils.h"


@implementation NSString (Jid)

- (NSString*)bareJid {
    NSArray* c = [self componentsSeparatedByString:@"/"];
    
    return c.first;
}
- (NSString*)jidResource {
    NSArray* c = [self componentsSeparatedByString:@"/"];
    
    if (c.count == 2)
        return c[1];
    
    return nil;
}

@end

@implementation XMLNode (XMPP)
- (NSString*)type {
    return self.attributes[@"type"];
}
- (NSString*)from {
    return self.attributes[@"from"];
}
- (NSString*)to {
    return self.attributes[@"to"];
}

@end