//
//  MulticastDelegate.m
//  Simple Talk
//
//  Created by Joel Edström on 3/31/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "MulticastDelegate.h"

@interface DelegateHolder : NSObject
@property (weak) id delegate;
@end
@implementation DelegateHolder @end

@implementation MulticastDelegate {
    NSMutableArray* _delegates;
    dispatch_queue_t _queue;
}

- (id)init
{
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create("multicast delegate", NULL);
        _delegates = [NSMutableArray new];
    }
    return self;
}

- (void)addDelegate:(id)delegate {
    dispatch_sync(_queue, ^{
        DelegateHolder* holder = [DelegateHolder new];
        holder.delegate = delegate;
        [_delegates addObject:holder];
    });
}
- (void)iterateDelegatesOnQueue:(dispatch_queue_t)delegateQueue
                      withBlock:(void (^)(id delegate))block {
    
    __block NSArray* delegates;
    dispatch_sync(_queue, ^{
        delegates = [_delegates copy];
    });
    
    dispatch_async(delegateQueue, ^{
        for (DelegateHolder* delegateHolder in delegates) {
            if (delegateHolder.delegate)
                block(delegateHolder.delegate);
        }
    });
    
    // prune
    dispatch_async(_queue, ^{
        for (DelegateHolder* delegateHolder in _delegates)
            if (!delegateHolder.delegate)
                [_delegates removeObject:delegateHolder];
    });
    
}
@end
