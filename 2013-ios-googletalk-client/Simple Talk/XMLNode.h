//
//  XMLNode.h
//  Simple Talk
//
//  Created by Joel Edström on 3/28/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMLNode : NSObject
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSArray* children;
@property (nonatomic, readonly) NSDictionary* attributes;
@property (nonatomic, readonly) NSString* text;
- (id)initWithName:(NSString*)name
          children:(NSArray*)children
        attributes:(NSDictionary*)attributes
              text:(NSString*)text;
+ (XMLNode*)parseData:(NSData*)data;
@end


@interface XMLNode(Useful)
- (XMLNode*)childWithName:(NSString*)name;
- (NSArray*)childrenWithName:(NSString*)name;
- (NSArray*)childrenMatchingFilter:(BOOL (^)(XMLNode* x))filter;
@end