//
//  XMLNode+XMPP.h
//  GTell
//
//  Created by Joel Edström on 3/16/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPParser.h"

@interface NSString (Jid)
- (NSString*)bareJid;
- (NSString*)jidResource;
@end


@interface XMLNode (XMPP)
- (NSString*)type;
- (NSString*)from;
- (NSString*)to;
@end

