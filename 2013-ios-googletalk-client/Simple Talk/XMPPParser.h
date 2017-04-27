//
//  XMPPParser.h
//  GTell
//
//  Created by Joel Edström on 3/16/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLNode.h"



@protocol XMPPParserDelegate
- (void)foundRoot;
- (void)foundStanza:(XMLNode*)node;
- (void)foundEnd:(NSError*)error;
@end
@interface XMPPParser : NSObject
@property (nonatomic, readonly) XMLNode* root;
- (id)initWithDelegate:(id <XMPPParserDelegate>)delegate
         delegateQueue:(dispatch_queue_t)queue;
- (void)parseData:(NSData*)data;
- (void)abort;
@end

