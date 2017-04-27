//
//  GmailChatHistoryClient.m
//  GTell
//
//  Created by Joel Edström on 3/26/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "GmailChatHistoryClient.h"
#import "JESocket.h"
#import "Base64.h"
#import "IMAPStream.h"
#import "Utils.h"
#import "XMLNode.h"
#import "XMLNode+XMPP.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;


@interface GmailChatHistoryClient () @end

@implementation GmailChatMessage
- (NSString *)description {
    
    return [NSString stringWithFormat:@"GmailChatMessage(%@, %@, %lld, %lld, %@)",
            self.fromJid, self.toJid, self.uid, self.date, self.body];
}
- (id)initWithToJid:(NSString*)toJid
            fromJid:(NSString*)fromJid
               body:(NSString*)body
               date:(int64_t)date
                uid:(int64_t)uid {
    self = [super init];
    if (self) {
        _toJid = toJid;
        _fromJid = fromJid;
        _body = body;
        _date = date;
        _uid = uid;
    }
    return self;
}
@end

@implementation GmailChatHistoryClient {
    dispatch_queue_t _queue;
    dispatch_queue_t _callbackQueue;
    IMAPStream* _imap;
    BOOL _connected;
    NSString* _account;
    NSString* _accessToken;
}
- (id)initWithAccount:(NSString*)account
          accessToken:(NSString*)accessToken
        callbackQueue:(dispatch_queue_t)callbackQueue {
    
    self = [super init];
    
    if (self) {
        _queue = dispatch_queue_create("GmailChatHistoryClient", NULL);
        _accessToken = accessToken;
        _account = account;
        _callbackQueue = callbackQueue;
    }
    return self;
}

- (void)connect:(void (^)(NSError* error, u_int32_t uidValidityOfChatMailbox))completionHandler {
    dispatch_async(_queue, ^{
        
        NSError* error = [NSError errorWithDomain:@"GmailChatHistory" code:0 userInfo:nil];
        
        
        void (^complete)(NSError*, u_int32_t) = ^(NSError* e, u_int32_t u) {
            dispatch_async(_callbackQueue, ^{
                completionHandler(e, u);
            });
        };
        
        
        
        _imap = [[IMAPStream alloc] initWithDelegate:nil delegateQueue:_queue connectTo:@"imap.gmail.com" port:993 ssl:YES];
        NSString* auth = [[NSString stringWithFormat:@"user=%@\1auth=Bearer %@\1\1", _account, _accessToken] toBase64];
        
        [_imap sendCommand:[NSString stringWithFormat:@"AUTHENTICATE XOAUTH2 %@\r\n", auth] continueWith:^(IMAPResponse *response) {
                  
            if (response.statusCode == IMAPResponseOK) {
                
                [_imap sendCommand:@"ID (\"name\" \"Simple Talk\")\r\n" continueWith:^(IMAPResponse *response) {
                    
                    if (response.statusCode == IMAPResponseOK) {
                        
                        [_imap sendCommand:@"EXAMINE \"[Gmail]/Chats\"\r\n" continueWith:^(IMAPResponse *response) {
                            
                            if (response.statusCode == IMAPResponseOK) {
                                
                                DDLogVerbose(@"got: %@", response);
                                _connected = YES;
                                
                                //TODO: parse uidValidity
                                complete(nil, 0);
                                
                            } else {
                                complete(error, 0);
                            }
                        }];
                    } else {
                        complete(error, 0);
                    }
                }];
            } else {
                complete(error, 0);
            }
        }];
    });
}


- (void)fetchMessagesSince:(u_int32_t)uid
                inChucksOf:(NSInteger)chuckSize
              whenFinished:(void (^)(NSError* error, NSArray* messages))completionHandler {
    
    dispatch_async(_queue, ^{
        
        void (^error)(NSString*) = ^(NSString* msg){
            NSError* e = [NSError errorWithDomain:msg code:0 userInfo:nil];
            dispatch_async(_callbackQueue, ^{
                completionHandler(e, nil);
            });
        };
        
        if (!_connected) {
            error(@"not connected");
            return;
        }
        
        NSString* c = [NSString stringWithFormat:@"uid fetch %d:%d body[1]\r\n", uid, uid+chuckSize];
        
        [_imap sendCommand:c continueWith:^(IMAPResponse *response) {
            DDLogVerbose(@"got: %@", response);
                        
            NSArray* messages = [self parseMessageFetch:response];
            
            if (messages) {
                dispatch_async(_callbackQueue, ^{
                    completionHandler(nil, messages);
                });
                
            } else {
                error(@"parse error");
            }
            
            
        }];
    });
}

- (NSArray*)parseMessageFetch:(IMAPResponse*)r {
    
    if (r.statusCode == IMAPResponseOK) {
        
        NSString* regex = @"^\\* [0-9]+ FETCH \\(UID ([0-9]+) BODY\\[1\\] \\{([0-9]+)\\}$";
        
        NSRegularExpression* matchHeaders = [[NSRegularExpression alloc] initWithPattern:regex options:NSRegularExpressionAnchorsMatchLines error:nil];
        
        
        NSString* responseText = [r.linesAsLatin1 foldLeft:[NSMutableString new] with:^(id a,id x) {
            [a appendString:x];
            [a appendString:@"\r\n"];   // add back CRLF so that data len matches original
            return a;
        }];
        
        
        NSArray* headerMatches = [matchHeaders matchesInString:responseText options:0 range:NSMakeRange(0, responseText.length)];
        
        return [headerMatches flatMap:^(NSTextCheckingResult* match) {
            DDLogVerbose(@"match");
            
            NSRange cap1Range = [match rangeAtIndex:1];
            NSString* capture1 = [responseText substringWithRange:cap1Range];
            
            NSRange cap2Range = [match rangeAtIndex:2];
            NSString* capture2 = [responseText substringWithRange:cap2Range];
            
            NSInteger loc = cap2Range.location + cap2Range.length + 3; // ['}', '\r', '\n'].len == 3
            NSInteger messageLen = [capture2 integerValue];
            
            NSString* message = [responseText substringWithRange:NSMakeRange(loc, messageLen)];
            
            NSData* messageData = [message dataUsingEncoding:NSISOLatin1StringEncoding];
            
            
            
            XMLNode* node = [XMLNode parseData:messageData] ?:
                [XMLNode parseData:[message.decodeQuotedPrintable dataUsingEncoding:NSUTF8StringEncoding]];
            
            
            DDLogVerbose(@"messageLen: %d uid: %lld message: [%@], node: [%@]", messageLen, capture1.longLongValue, message, node);
            
            if (!node)
                DDLogInfo(@"FAIL PARSE: %@", message);
            
            return [self parseXMLConversation:node withUid:capture1.longLongValue];
        }];
    }

    return nil;
}

- (NSArray*)parseXMLConversation:(XMLNode*)node withUid:(int64_t)uid {
    
    return [[node childrenMatchingFilter:^BOOL(XMLNode *x) {
        return [x.name isEqual:@"cli:message"] || [x.name isEqual:@"message"];
    }] map:^id(XMLNode* msgNode) {
        
        NSString* fromJid = [msgNode.attributes[@"from"] bareJid];
        NSString* toJid = [msgNode.attributes[@"to"] bareJid];
        NSString* body = [msgNode childWithName:@"cli:body"].text ?: [msgNode childWithName:@"body"].text;
        int64_t date = [[msgNode childWithName:@"time"].attributes[@"ms"] longLongValue];
            
        return [[GmailChatMessage alloc] initWithToJid:toJid fromJid:fromJid body:body date:date uid:uid];
    }];
}


// TODO: detect chat mailbox

/*[_imap sendCommand:@"LIST \"\" \"*\"\r\n" continueWith:^(IMAPResponse *response) {
 
 NSLog(@"got: %@", response);
 
 for (NSString* l in [self parseList:response.linesAsUTF8]) {
 NSLog(@"mailbox: %@", l);
 }
 }];*/


// for detecting chat mailbox, message contains: NSString* chatNamespace = @"google:archive:conversation";
- (NSArray*)parseList:(NSArray*)lines {
    NSRegularExpression* matchLine =
        [[NSRegularExpression alloc] initWithPattern:@"\\* LIST \\(.*\\) \"/\" \"(.*)\"" options:0 error:nil];
    
    
    return [lines map:^(NSString* line) {
        NSTextCheckingResult* r = [matchLine firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
        NSRange rangeOfCapture = [r rangeAtIndex:1];
        NSString* capture = [line substringWithRange:rangeOfCapture];
        
        return capture;
    }];
}


@end
