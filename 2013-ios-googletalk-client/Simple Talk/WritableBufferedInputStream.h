//
//  WritableBufferedInputStream.h
//  GTell
//
//  Created by Joel Edström on 3/16/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WritableBufferedInputStream : NSInputStream
- (void)write:(NSData*)data;
- (void)finish;
@end


