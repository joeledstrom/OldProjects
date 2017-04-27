//
//  JESocket.h
//  GTell
//
//  Created by Joel Edström on 3/15/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>



@protocol JESocketDelegate <NSObject>
@required
// return how many bytes consumed, remaining data will be queued up for next callback
- (NSUInteger)consumeData:(NSData*)data;

- (void)socketError:(NSError*)error;
@end

@interface JESocket : NSObject
- (id)initWithDelegate:(id <JESocketDelegate>)delegate
         delegateQueue:(dispatch_queue_t)queue
             connectTo:(NSString*)host
                  port:(u_int32_t)port
                   ssl:(BOOL)ssl;

- (void)sendData:(NSData*)data;
- (void)close;
- (void)startTLS;
@end
