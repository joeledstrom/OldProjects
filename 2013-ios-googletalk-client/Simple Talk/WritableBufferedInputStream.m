//
//  WritableBufferedInputStream.m
//  GTell
//
//  Created by Joel Edström on 3/16/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "WritableBufferedInputStream.h"

@implementation WritableBufferedInputStream {
    NSMutableData* _data;
    dispatch_queue_t _queue;
    NSConditionLock* _lock;
    BOOL _finishFlag;
}

enum {
    NO_DATA, HAS_DATA
};

- (id)init
{
    self = [super init];
    if (self) {
        _data = [NSMutableData new];
        _lock = [[NSConditionLock alloc] initWithCondition:NO_DATA];
        _queue = dispatch_queue_create("WritableBufferingInputStream", NULL);
    }
    return self;
}

- (void)write:(NSData*)data {
    dispatch_async(_queue, ^{
        [_lock lock];
        [_data appendData:data];
        [_lock unlockWithCondition:HAS_DATA];
    });
}

- (void)finish {
    NSLog(@"WBIS finished by writer");
    dispatch_async(_queue, ^{
        [_lock lock];
        _finishFlag = YES;
        [_lock unlockWithCondition:HAS_DATA];
    });
}

- (void)open { NSLog(@"WBIS opened on thread: %@", [NSThread currentThread].debugDescription);}
- (void)close { NSLog(@"WBIS closed by reader"); }
- (BOOL)hasBytesAvailable { return YES; }
- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len { return NO; }

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    
    [_lock lockWhenCondition:HAS_DATA];
    
    
    if (_finishFlag) {
        [_lock unlock];
        return 0;
    }
    
    NSInteger bytesRead = MIN(_data.length, len);
    [_data getBytes:buffer length:bytesRead];
    
    [_data replaceBytesInRange:NSMakeRange(0, bytesRead)
                     withBytes:nil
                        length:0];
    
    BOOL dataLeft = _data.length > 0 ? HAS_DATA : NO_DATA;
    
    
    [_lock unlockWithCondition:dataLeft];
    return bytesRead;
}

@end
