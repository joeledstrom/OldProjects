//
//  JESocket.m
//  GTell
//
//  Created by Joel Edström on 3/15/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "JESocket.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;


@interface JESocket() <NSStreamDelegate> @end

@implementation JESocket {
    __weak id <JESocketDelegate> _delegate;
    dispatch_queue_t _delegateQueue;
    NSInputStream* _inputStream;
    NSOutputStream* _outputStream;
    NSMutableArray* _sendQueue;
    NSRunLoop* _socketRunLoop;
    NSThread* _socketThread;
    BOOL _opened;
    NSMutableData* _consumeBuffer;   // owned by delegateQueue
    dispatch_semaphore_t _threadStarted;
}
- (id)initWithDelegate:(id <JESocketDelegate>)delegate
         delegateQueue:(dispatch_queue_t)queue
             connectTo:(NSString*)host
                  port:(u_int32_t)port
                   ssl:(BOOL)ssl {

    self = [super init];
    if (self) {
        _delegate = delegate;
        _delegateQueue = queue;
        _sendQueue = [NSMutableArray new];
        // "The objects aTarget and anArgument are retained during the execution of the detached thread, then released"
        
        _threadStarted = dispatch_semaphore_create(0);
        _socketThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMain) object:nil];
        [_socketThread start];
        
        
        dispatch_semaphore_wait(_threadStarted, DISPATCH_TIME_FOREVER);
        
        
        [self performOnThread:^{
            CFReadStreamRef readStream;
            CFWriteStreamRef writeStream;
            CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, port, &readStream, &writeStream);
            _inputStream = CFBridgingRelease(readStream);
            _outputStream = CFBridgingRelease(writeStream);
            _inputStream.delegate = self;
            _outputStream.delegate = self;
            [_inputStream scheduleInRunLoop:_socketRunLoop forMode:NSDefaultRunLoopMode];
            [_outputStream scheduleInRunLoop:_socketRunLoop forMode:NSDefaultRunLoopMode];
            
            if (ssl)
                [self enableSSL];
            
            [_inputStream open];
            [_outputStream open];
        }];
    }
    return self;
}

- (void)threadMain {
    @autoreleasepool {
        _socketRunLoop = [NSRunLoop currentRunLoop];
        dispatch_semaphore_signal(_threadStarted);
        while (![[NSThread currentThread] isCancelled]) {
            @autoreleasepool {
                [_socketRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            }
        }
    }
    DDLogInfo(@"JESocket Runloop-thread died");
}

- (void)enableSSL {
    NSDictionary* settings = @{(NSString*)kCFStreamSSLLevel: NSStreamSocketSecurityLevelTLSv1};
    [_inputStream setProperty:settings forKey:(NSString*)kCFStreamPropertySSLSettings];
    [_outputStream setProperty:settings forKey:(NSString*)kCFStreamPropertySSLSettings];
}
- (void)startTLS {
    [self performOnThread:^{
        [self enableSSL];
        [_inputStream open];
        [_outputStream open];
    }];
}

- (void)dealloc {
    //assert([_socketThread isFinished]);
}
- (void)sendData:(NSData*)data {
    [self performOnThread:^{
        [_sendQueue addObject:data];
        [self trySend];
    }];
}

- (void)performOnThread:(dispatch_block_t)block {
    
    [self performSelector:@selector(doPerform:) onThread:_socketThread withObject:[block copy] waitUntilDone:NO];
}

- (void)doPerform:(dispatch_block_t)block {
    
    block();
}

- (void)endStream:(NSError*)e {
    dispatch_async(_delegateQueue, ^{
        [_delegate socketError:e];
    });
}

- (void)close {
    dispatch_sync(_delegateQueue, ^{
        _delegate = nil;
    });
    [self performOnThread:^{
        [self doClose];
    }];
}

- (void)doClose {
    [_inputStream close];
    [_outputStream close];
    [_inputStream removeFromRunLoop:_socketRunLoop forMode:NSDefaultRunLoopMode];
    [_outputStream removeFromRunLoop:_socketRunLoop forMode:NSDefaultRunLoopMode];
    [_socketThread cancel];
}


- (void)tryConsume {
    dispatch_async(_delegateQueue, ^{
        NSUInteger bytesConsumed = [_delegate consumeData:[_consumeBuffer copy]];
        
        //NSLog(@"try consume");
        if (bytesConsumed > 0) {
            
            //NSLog(@"bytesConsumed: %d, bytesLeft: %d", bytesConsumed, _consumeBuffer.length-bytesConsumed);
            
            [_consumeBuffer replaceBytesInRange:NSMakeRange(0, bytesConsumed)
                                      withBytes:nil
                                         length:0];
            
            
            if (_consumeBuffer.length > 0) { // consumer used smaller readbuffer than the size of _consumeBuffer
                [self tryConsume];
            }
        }
        // else consumer waits for more data from socket before it can parse
        
        
    });
}

- (void)tryRead {
    
    BOOL readBufferTouched = NO;
    
    while (_inputStream.hasBytesAvailable) {
        @autoreleasepool {
            uint8_t buf[1024];    // TODO: TEST
            NSUInteger bufLen = sizeof(buf)/sizeof(uint8_t);
            NSInteger bytesRead = [_inputStream read:buf maxLength:bufLen];
            
            if (bytesRead == -1) {
                [self endStream:_outputStream.streamError];
                break;
            }
            
            if (bytesRead > 0) {
                NSData* data = [NSData dataWithBytes:buf length:bytesRead];
                
                dispatch_async(_delegateQueue, ^{
                    
                    if (!_consumeBuffer) _consumeBuffer = [NSMutableData new];
                    
                    [_consumeBuffer appendData:data];
                });
                
                readBufferTouched = YES;
            }
        }
    }
    
    if (readBufferTouched)
        [self tryConsume];
    
}

- (void)trySend {
    while (_opened && _outputStream.hasSpaceAvailable && _sendQueue.count > 0) {
        NSData* data = _sendQueue[0]; [_sendQueue removeObjectAtIndex:0];
        NSInteger bytesWritten = [_outputStream write:data.bytes maxLength:data.length];
        
        DDLogVerbose(@"wrote: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        
        if (bytesWritten == -1) {
            [self endStream:_outputStream.streamError];
            return;
        }
        
        if (bytesWritten < data.length) {
            data = [data subdataWithRange:NSMakeRange(bytesWritten, data.length - bytesWritten)];
            [_sendQueue insertObject:data atIndex:0];
        }
    }
}



#pragma mark - NSStreamDelegate
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    switch (streamEvent) {
        case NSStreamEventOpenCompleted:
            _opened = YES;
            DDLogVerbose(@"stream opened");
            break;
        case NSStreamEventHasSpaceAvailable:
            //_hasSpaceAvailable = YES;
            [self trySend];
            break;
        case NSStreamEventHasBytesAvailable:
            // _hasBytesAvailable = YES;
            [self tryRead];
            break;
        case NSStreamEventEndEncountered:
        case NSStreamEventErrorOccurred:
            [self endStream:theStream.streamError];
            [self doClose];
            break;
        case NSStreamEventNone:
            break;
    }
    
}


@end
