//
//  UtilsTest.m
//  GTell
//
//  Created by Joel Edström on 3/18/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "UtilsTest.h"
#import "Utils.h"

@implementation UtilsTest
- (void)testMap {
    NSArray* a = @[@3, @6, @1, @9];
    
    NSArray* b = [a map:^(NSNumber* x) {
        return @(x.integerValue * 2);
    }];
    NSArray* c = @[@6, @12, @2, @18];
    
    STAssertEqualObjects(b, c, @"map works");
}

- (void)testFilter {
    NSArray* a = @[@3, @6, @1, @9];
    
    
    NSArray* b = [[a map:^(NSNumber* x) {
        return @(x.integerValue * 2);
    }] filter:^(NSNumber* x) {
        return (BOOL)(x.integerValue > 15);
    }];
    NSArray* c = @[@18];
    
    STAssertEqualObjects(b, c, @"filter works");
}

- (void)testPrependAppend {
    
    NSArray* a = @[@3, @6, @1, @9];
    
    a = [a prepend:@4];
    NSArray* x = a;
    a = [a arrayByAddingObject:@5];
    a = [a prepend:@6];
    
    NSArray* b = [a append:@99];
    
    b = [b prepend:@0];
    
    NSArray* c = @[@0, @6,@4,  @3, @6, @1, @9,@5,  @99];
    
    
    
    
    [x prepend:@4];   //nop
    [x force]; //nop
    x = [x prepend:@11];
    x = [x force];
    x = [x append:@7];
    
    NSArray* y = @[@11,  @4,@3, @6, @1, @9, @7];
    
    STAssertTrue([b isEqualToArray:c], @"prepend/append works");
    STAssertEqualObjects(b, c, @"prepend/append works");
    STAssertEqualObjects(x, y, @"prepend/append with force works");
    
    
}

- (void)testFoldLeft {
    NSArray* a = @[@3, @6, @1, @9];
    
    NSNumber* sum = [a foldLeft:@0 with:^(NSNumber* a, NSNumber* x) {
        return @(a.integerValue + x.integerValue);
    }];
    
    STAssertEquals(sum.integerValue, 19, @"summing works");
}

- (NSArray*)append1000:(NSArray*)a {
    id obj = @4;
    
    for (int i = 0; i < 1000; i++)
        a = [a append:obj];
    
    return a;
}

- (NSArray*)append1000abao:(NSArray*)a {
    id obj = @4;
    
    for (int i = 0; i < 1000; i++)
        a = [a arrayByAddingObject:obj];
    
    return a;
}


- (void)testBenchmarkNonDeterministic {
    NSArray* a = @[];
    
    
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    for (int i = 0; i < 10; i++)
        @autoreleasepool {
            a = [self append1000:a];
        }
    

    
    NSTimeInterval appendToList = [[NSDate date] timeIntervalSince1970] - start;
    
    NSArray* c;
    @autoreleasepool {
        c = [a force];
    }
    
    
    NSTimeInterval total = [[NSDate date] timeIntervalSince1970] - start;
    
    
    NSArray* b = @[];
    
    start = [[NSDate date] timeIntervalSince1970];
    for (int i = 0; i < 10; i++)
        @autoreleasepool {
            b = [self append1000abao:b];
        }
    
    NSTimeInterval arrayByAdding = [[NSDate date] timeIntervalSince1970] - start;

    
    NSLog(@"append to list took: %f seconds", appendToList);
    NSLog(@"force took: %f seconds", total-appendToList);
    NSLog(@"total time for ListArray append+force: %f seconds", total);
    
    NSLog(@"appending by using arrayByAddingObject took: %f seconds", arrayByAdding);
    
    
    STAssertTrue(arrayByAdding > total, @"ListArray has faster append then NSArrray");
    // STAssertEqualObjects(a, b, @"same result"); too slow
    STAssertEqualObjects(c, b, @"same result after force as well");
}
@end
