//
//  XMPPvCard.h
//  Simple Talk
//
//  Created by Joel Edström on 3/29/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPStream.h"


@protocol XMPPvCardDelegate <NSObject>
- (void)receivedVcard:(XMLNode*)vCard forJid:(NSString*)jid;
- (void)vCardUpdateForJid:(NSString*)jid receviedWithHash:(NSString*)hash;
@end

@interface XMPPvCard : NSObject <XMPPModule>
- (id)initWithDelegate:(id <XMPPvCardDelegate>)delegate;
- (void)fetchVCardForJid:(NSString*)jid;
@end
