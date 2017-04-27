//
//  Utils.h
//  GTell
//
//  Created by Joel Edström on 3/18/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>




@interface NSArray (UsefulStuff)
- (id)first;
- (NSArray*)flatMap:(NSArray* (^)(id))f;
- (NSArray*)map:(id (^)(id x))f;
- (id)foldLeft:(id)a with:(id (^)(id a, id x))f;
- (NSArray*)filter:(BOOL (^)(id x))f;
- (NSArray*)concat:(NSArray*)array;


// experiment
- (NSArray*)append:(id)object;
- (NSArray*)prepend:(id)object;
- (NSArray*)force;
@end


@interface NSString (XML)
- (NSString*)xmlEscapesDecode;
- (NSString*)xmlEscapesEncode;
- (NSString*)decodeQuotedPrintable;
@end


@interface NSMutableArray(Stack)
- (void)push:(id)object;
- (id)pop;
- (id)head;
@end