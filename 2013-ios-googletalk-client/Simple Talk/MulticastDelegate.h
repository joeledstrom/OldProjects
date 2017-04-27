//
//  MulticastDelegate.h
//  Simple Talk
//
//  Created by Joel Edström on 3/31/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MulticastDelegate : NSObject
- (void)addDelegate:(id)delegate;
- (void)iterateDelegatesOnQueue:(dispatch_queue_t)delegateQueue withBlock:(void (^)(id delegate))block;
@end
