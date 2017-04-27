//
//  ImapStream.m
//  GTell
//
//  Created by Joel Edström on 3/27/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "IMAPStream.h"
#import "JESocket.h"
#import "Utils.h"


@implementation IMAPResponse {
    NSArray* _data;
}

- (id)initWithRawData:(NSArray*)data statusCode:(IMAPResponseStatusCode)statusCode statusMessage:(NSString*)msg
{
    self = [super init];
    if (self) {
        _data = data;
        _statusCode = statusCode;
        _statusMessage = msg;
    }
    return self;
}

- (NSArray*)linesAsModifiedUTF7 {
    return @[];
}

- (NSArray*)linesAsUTF8 {
    return [_data map:^id(NSData* x) {
        return [[NSString alloc] initWithData:x encoding:NSUTF8StringEncoding];
    }];
}

- (NSArray*)linesAsASCII {
    return [_data map:^id(NSData* x) {
        return [[NSString alloc] initWithData:x encoding:NSASCIIStringEncoding];
    }];
}

- (NSArray*)linesAsLatin1 {
    return [_data map:^id(NSData* x) {
        return [[NSString alloc] initWithData:x encoding:NSISOLatin1StringEncoding];
    }];
}



- (NSString *)description {
    
    NSString* code = _statusCode == IMAPResponseOK ? @"OK" :
                     _statusCode == IMAPResponseNO ? @"NO" :
                     _statusCode == IMAPResponseBAD ? @"BAD" : @"unknown";
    
    NSMutableString* s = [NSMutableString new];
    [s appendString:[NSString stringWithFormat:@"IMAPResponse[[code = %@, msg = %@] [", code, _statusMessage]];
    for (NSString* l in [self linesAsUTF8]) {
        [s appendString:l];
        [s appendString:@"\n"];
    }
    [s appendString:@"]]"];
    return s;
}


@end


@interface IMAPStream () <JESocketDelegate> @end


@implementation IMAPStream {
    JESocket* _socket;
    dispatch_queue_t _queue;
    dispatch_queue_t _delegateQueue;
    u_int64_t _commandTag;
    NSMutableDictionary* _commandsInProgress;
    NSMutableArray* _linesBuffer;
    
}
- (id)initWithDelegate:(id <IMAPStreamDelegate>)delegate
         delegateQueue:(dispatch_queue_t)delQueue
             connectTo:(NSString*)host
                  port:(u_int32_t)port
                   ssl:(BOOL)ssl {
    self = [super init];
    
    if (self) {
        _delegateQueue = delQueue;
        _commandTag = 1;
        _queue = dispatch_queue_create("IMAPStream", NULL);
        _socket = [[JESocket alloc] initWithDelegate:self delegateQueue:_queue connectTo:host port:port ssl:ssl];
        _commandsInProgress = [NSMutableDictionary new];
        _linesBuffer = [NSMutableArray new];
        
    }
    return self;
}

- (NSString*)getNextCommandTag {
    return [NSString stringWithFormat:@"=_%lld", _commandTag++];
}

- (void)sendData:(NSString*)data {
    [_socket sendData:[data dataUsingEncoding:NSASCIIStringEncoding]];
}

- (NSUInteger)consumeData:(NSData *)data {
    
    if (data.length < 2)
        return 0;
    
    const char* bytes = data.bytes;
    
    int foundCRLFAt = -1;
    
    int lineOffset = 0;
    
    for (int i = 0; i < data.length-1; i++) {
        if (bytes[i] == '\r' && bytes[i+1] == '\n') {
            foundCRLFAt = i;
            [_linesBuffer addObject:[data subdataWithRange:NSMakeRange(lineOffset, foundCRLFAt-lineOffset)]];
            lineOffset = i+2;
            
            i++; // skip \r
            //break;
        }
    }
    
    if (foundCRLFAt == -1)
        return 0;
    
    
    //NSLog(@"%@", [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, foundCRLFAt)] encoding:NSUTF8StringEncoding]);
    [self tryParseLines];
    
    return foundCRLFAt + 2;
}

- (void)foundParseError {
    NSLog(@"foundParseError");
}

- (void)tryParseLines {
    NSData* lastRowData = [_linesBuffer lastObject];
    NSString* lastRow = [[NSString alloc] initWithData:lastRowData encoding:NSUTF8StringEncoding];
    
    
    NSArray* c = [lastRow componentsSeparatedByString:@" "];
    
    NSDictionary* statusCodes = @{@"OK": @(IMAPResponseOK),
                                  @"NO": @(IMAPResponseNO),
                                  @"BAD": @(IMAPResponseBAD)};
    
    if (c.count > 1 && statusCodes[[c[1] uppercaseString]] && _commandsInProgress[c[0]]) {
        
        NSArray* rowsAbove = [_linesBuffer subarrayWithRange:NSMakeRange(0, _linesBuffer.count-1)];
        [_linesBuffer removeAllObjects];
        
        
        // get status message (if any)
        NSString* status = nil;
        if (c.count > 2) {
            NSRange rangeOfStatus = [lastRow rangeOfString:c[1]];
            NSInteger indexOfStatusMessage = rangeOfStatus.location + rangeOfStatus.length + 1;
            status = [lastRow substringFromIndex:indexOfStatusMessage];
        }
        
        void (^h)(IMAPResponse*) = _commandsInProgress[c[0]];
        
        dispatch_async(_delegateQueue, ^{
            h([[IMAPResponse alloc] initWithRawData:rowsAbove
                                         statusCode:[statusCodes[[c[1] uppercaseString]] integerValue]
                                      statusMessage:status]);
        });
        
        
        [_commandsInProgress removeObjectForKey:c[0]];
    }
}



- (void)socketError:(NSError *)error {
    // TODO:
    NSLog(@"IMAPStream: socket error");
}



- (void)sendCommand:(NSString*)command continueWith:(void (^)(IMAPResponse* response))handler {
    void (^h)(IMAPResponse* response) = [handler copy];
    dispatch_async(_queue, ^{
        NSString* tag = [self getNextCommandTag];
        _commandsInProgress[tag] = h;
        [self sendData:[NSString stringWithFormat:@"%@ %@", tag, command]];
    });
}
@end
