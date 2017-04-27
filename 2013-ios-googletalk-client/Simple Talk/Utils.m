//
//  Utils.m
//  GTell
//
//  Created by Joel Edström on 3/18/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "Utils.h"




@implementation NSString (XML)

- (NSString *)xmlEscapesDecode {
    return [[[[[self stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""]
       stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"]
       stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"]
       stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"]
       stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
}

- (NSString *)xmlEscapesEncode {
    return [[[[[self stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"]
       stringByReplacingOccurrencesOfString:@"'" withString:@"&apos;"]
       stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"]
       stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"]
       stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
}

- (NSString*)decodeQuotedPrintable {
    
    NSString *convertedString = [self mutableCopy];
    
    if ([convertedString rangeOfString:@"\\"].location != NSNotFound) {
        CFStringRef transform = CFSTR("Any-Hex/Java");
        CFStringTransform((__bridge CFMutableStringRef)convertedString, NULL, transform, YES);
    }
    
    
    
    return [[[convertedString stringByReplacingOccurrencesOfString:@"=\r\n" withString:@""]
    stringByReplacingOccurrencesOfString:@"=" withString:@"%"]
    stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end






#define isAppendList (_size > 0)
#define isPrependList (_size < 0)

@interface LinkNode : NSObject 
@property (readonly, nonatomic) LinkNode* next;
@property (readonly, nonatomic) id value;
@end

@implementation LinkNode
- (id)initWithNext:(LinkNode*)next value:(id)value
{
    self = [super init];
    if (self) {
        _next = next;
        _value = value;
    }
    return self;
}
@end


@interface ListArray : NSArray
@end

@implementation ListArray {
    NSArray* _array;
    NSInteger _size;
    LinkNode* _node;
}

- (id)initWithArray:(NSArray *)array
         appendList:(LinkNode*)appendNode
         appendSize:(NSInteger)appendSize
{
    self = [super init];
    if (self) {
        _array = array;
        _node = appendNode;
        _size = appendSize;
        
    }
    return self;
}
- (id)initWithArray:(NSArray *)array
        prependList:(LinkNode*)prepNode
        prependSize:(NSInteger)prepSize
{
    self = [super init];
    if (self) {
        _array = array;
        _node = prepNode;
        _size = -prepSize;
        
    }
    return self;
}



- (NSUInteger)count {
    return _array.count + ABS(_size);
}

- (id)objectAtIndex:(NSUInteger)index {
    if (index < self.count) {
        
        if (isAppendList && index < _array.count)
            return _array[index];
        
        if (isPrependList && index >= _size)
            return _array[index-_size];
        
        return self.merge[index];
    } else {
        @throw [NSException exceptionWithName:NSRangeException reason:NSRangeException userInfo:nil];
    }
}

- (NSArray*)merge {
    NSMutableArray *a = [[NSMutableArray alloc] initWithCapacity:self.count];
    
    if (isAppendList) {
        [a addObjectsFromArray:_array];
        
        NSMutableArray* reverse = [[NSMutableArray alloc] initWithCapacity:_size];
        for (LinkNode* cur = _node; cur != nil; cur = cur.next)
            [reverse addObject:cur.value];
        
        for (int i = reverse.count-1; i >= 0; i--)
            [a addObject:reverse[i]];
        
    } else {
        for (LinkNode* cur = _node; cur != nil; cur = cur.next)
            [a addObject:cur.value];
        
        [a addObjectsFromArray:_array];
    }
    
    return a;
}

- (NSArray*)force {
    return self.merge;
}

- (NSArray*)append:(id)object {
    if (isAppendList)
        return [[ListArray alloc] initWithArray:_array
                                     appendList:[[LinkNode alloc] initWithNext:_node value:object]
                                     appendSize:_size + 1];
    else
        return [[ListArray alloc] initWithArray:self.merge
                                     appendList:[[LinkNode alloc] initWithNext:nil value:object]
                                     appendSize:1];
    
    
}

- (NSArray*)prepend:(id)object {
    if (isPrependList)
        return [[ListArray alloc] initWithArray:_array
                                     prependList:[[LinkNode alloc] initWithNext:_node value:object]
                                     prependSize:ABS(_size) + 1];
        
    else
        return [[ListArray alloc] initWithArray:self.merge
                                    prependList:[[LinkNode alloc] initWithNext:nil value:object]
                                    prependSize:1];
    
}

@end


@implementation NSArray (UsefulStuff)

- (NSArray*)force {
    return self;
}

- (id)foldLeft:(id)a with:(id (^)(id a, id x))f {
    
    for (id x in self) {
        @autoreleasepool {
            a = f(a, x);
        }
        
    }
    
    return a;
}

- (NSArray*)flatMap:(NSArray* (^)(id))f {
    NSMutableArray* r = [NSMutableArray new];
    for (id x in self) {
        @autoreleasepool {
            id y = f(x);
            
            if (y) {
                for (id z in y) {
                    [r addObject:z];
                }
            }
        }
    }
    return r;
}

- (NSArray*)map:(id (^)(id))f {
    NSMutableArray* r = [NSMutableArray arrayWithCapacity:self.count];
    for (id x in self) {
        @autoreleasepool {
            id y = f(x);
            if (y)
                [r addObject:y];
        }
        
    }
    return r;
}
- (NSArray*)filter:(BOOL (^)(id x))f {
    NSMutableArray* r = [NSMutableArray arrayWithCapacity:self.count];
    for (id x in self) {
        @autoreleasepool {
            if (f(x))
                [r addObject:x];
        }
        
    }
    return r;
}
- (NSArray*)concat:(NSArray*)array {
    NSMutableArray* r = [NSMutableArray arrayWithCapacity:self.count + array.count];
    [r addObjectsFromArray:self];
    [r addObjectsFromArray:array];
    return r;
}


- (NSArray*)append:(id)object {
    return [[ListArray alloc] initWithArray:self
                                  appendList:[[LinkNode alloc] initWithNext:nil value:object]
                                  appendSize:1];
    
}
- (NSArray*)prepend:(id)object {
    return [[ListArray alloc] initWithArray:self
                                 prependList:[[LinkNode alloc] initWithNext:nil value:object]
                                 prependSize:1];
    
}

- (id)first {
    return self.count > 0 ? self[0] : nil;
}

@end



@implementation NSMutableArray(Stack)
- (void)push:(id)object {
    [self addObject:object];
}
- (id)pop {
    id r = [self lastObject];
    if (r) [self removeLastObject];
    return r;
}
- (id)head {
    return [self lastObject];
}
@end