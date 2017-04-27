//
//  ImapStream.h
//  GTell
//
//  Created by Joel Edström on 3/27/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
    IMAPResponseOK,
    IMAPResponseNO,
    IMAPResponseBAD
} IMAPResponseStatusCode;

@interface IMAPResponse : NSObject
@property (nonatomic, readonly) NSArray* linesAsModifiedUTF7;
@property (nonatomic, readonly) NSArray* linesAsUTF8;
@property (nonatomic, readonly) NSArray* linesAsASCII;
@property (nonatomic, readonly) NSArray* linesAsLatin1;
@property (nonatomic, readonly) IMAPResponseStatusCode statusCode;
@property (nonatomic, readonly) NSString* statusMessage;
@end


@protocol IMAPStreamDelegate <NSObject>

@end

@interface IMAPStream : NSObject
- (id)initWithDelegate:(id <IMAPStreamDelegate>)delegate
         delegateQueue:(dispatch_queue_t)queue
             connectTo:(NSString*)host
                  port:(u_int32_t)port
                   ssl:(BOOL)ssl;
- (void)sendCommand:(NSString*)command continueWith:(void (^)(IMAPResponse* response))handler;

@end
