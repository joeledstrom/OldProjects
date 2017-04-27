//
//  RosterCacher.h
//  Simple Talk
//
//  Created by Joel Edström on 3/30/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPRoster2.h"
#import "XMPPvCard.h"


@interface RosterStore : NSObject <XMPPRoster2Delegate, XMPPvCardDelegate>
- (id)initWithManagedContext:(NSManagedObjectContext*)moc backendQueue:(dispatch_queue_t)queue;
- (void)setXMPPvCard:(XMPPvCard*)vcard;
@end
