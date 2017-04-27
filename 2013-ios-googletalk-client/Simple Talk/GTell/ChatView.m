//
//  ChatView.m
//  GTell
//
//  Created by Joel Edström on 3/9/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "ChatView.h"
#import <QuartzCore/QuartzCore.h>


@implementation ChatView


- (void)awakeFromNib {
    self.layer.cornerRadius = 5;
    //self.layer.shadowOpacity = 0.8;
    //self.layer.shadowOffset = CGSizeMake(0, 0);
    
    
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (CGSize)intrinsicContentSize {
    return [self contentSize];
}
@end
