//
//  SharedStatus.h
//  Simple Talk
//
//  Created by Joel Edström on 3/30/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SharedStatusDelegate <NSObject>
- (void)sharedStatusChanged;
@end

@interface SharedStatus : NSObject


- (void)setIdle;
- (void)setActive;
@end
