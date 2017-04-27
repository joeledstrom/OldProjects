//
//  MessageStore.m
//  Simple Talk
//
//  Created by Joel Edström on 3/30/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "MessageStore.h"
#import "GmailChatHistoryClient.h"
#import "XMPPMessaging.h"
#import "DDLog.h"
#import "Buddy.h"
#import "Message.h"
#import "Utils.h"
#import "XMLNode+XMPP.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@interface MessageStore () <XMPPMessagingDelegate> @end

@implementation MessageStore {
    GmailChatHistoryClient* _chatHistory;
    NSString* _account;
    NSString* _accessToken;
    BOOL _connected;
    NSManagedObjectContext* _moc;
    dispatch_queue_t _backendQueue;
    int64_t _cachedEarliestUID;
    int64_t _cachedLatestUID;
}
- (id)initWithManagedContext:(NSManagedObjectContext*)moc backendQueue:(dispatch_queue_t)queue
{
    self = [super init];
    if (self) {
        _moc = moc;
        _backendQueue = queue;
        _cachedLatestUID = -1;
        _cachedEarliestUID = -1;
    }
    return self;
}

- (void)setAuthInfoToAccount:(NSString*)account accessToken:(NSString*)token {
    _account = account;
    _accessToken = token;
    
    // invalidate uid cache, incase the user switched accounts
    _cachedLatestUID = -1;
    _cachedEarliestUID = -1;
    
    
    if (!_connected)
        [self connect];
}

- (void)connect {
    
    
    
    _chatHistory = [[GmailChatHistoryClient alloc] initWithAccount:_account accessToken:_accessToken callbackQueue:_backendQueue];
    [_chatHistory connect:^(NSError *error, u_int32_t uidValidityOfChatMailbox) {
        if (!error) {
            
            _connected = YES;
            
            [self fetchLatest];
        }
    }];
}

- (void)fetchLatest {
    if (_connected) {
        
        if (_cachedLatestUID < 1) {
        
            NSNumber* latest = [self fetchLatestUID];
            _cachedLatestUID = latest ? latest.longLongValue : 1;
        }
        
        DDLogInfo(@"Latest UID: %lld", _cachedLatestUID);
        
        int64_t oldLatestUID = _cachedLatestUID;
        
        [_chatHistory fetchMessagesSince:_cachedLatestUID inChucksOf:200 whenFinished:^(NSError *error, NSArray *messages) {
            [self processMessages:messages];
            
        }];
    } else {
        [self connect];
    }
}

- (void)messageReceived:(XMPPMessage*)msg {
    DDLogVerbose(@"XMPP Message Received %@", msg);

    [self addLocalMessage:msg];
}

- (void)addLocalMessage:(XMPPMessage*)msg {
    [_moc performBlock:^{
        
        Buddy* buddy = [self getOrCreateBuddy:msg.fromJid.bareJid];
        
        Message* newMsg = [NSEntityDescription insertNewObjectForEntityForName:@"Message"
                                                        inManagedObjectContext:_moc];
        newMsg.text = msg.body;
        newMsg.fromUser = !msg.incoming;
        newMsg.date = [[NSDate date] timeIntervalSince1970] * 1000;
        assert(newMsg.imapUID == nil);
        
        newMsg.buddy = buddy;
        [_moc save:nil];
    }];
}




- (void)processMessages:(NSArray*)messages {
    
    [_moc performBlock:^{
        int64_t lowestDate = INT64_MAX;
        int64_t highestDate = 0;
        
        for (GmailChatMessage* m in messages) {
            if (m.date > highestDate)
                highestDate = m.date;
            
            if (m.date < lowestDate)
                lowestDate = m.date;
        }
        
        
        DDLogInfo(@"lowestDate %lld, highestDate %lld", lowestDate, highestDate);
        
        
        int64_t tenMin = (1000 * 10 * 60);  // range for which matching messages except for date, is considered the same msg
        
        NSFetchRequest* fetchCloseMessages = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
        fetchCloseMessages.predicate =
        [NSPredicate predicateWithFormat:@"date > %lld AND date < %lld", lowestDate-tenMin, highestDate+tenMin];
        fetchCloseMessages.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
        fetchCloseMessages.relationshipKeyPathsForPrefetching = @[@"buddy"];
        
        NSError* error = NULL;
        NSArray* results = [_moc executeFetchRequest:fetchCloseMessages error:&error];
        
        
        NSUInteger msgCount = 0;
        
        if (results) {
            
            int64_t latestUID = 0;
            
            for (GmailChatMessage* msg in messages) {
                
                @autoreleasepool {
                    
                    
                    
                    DDLogVerbose(@"Begin processing: %@", msg);
                    
                    BOOL fromUser = [_account isEqual:msg.fromJid];
                    NSString* buddyJid =  fromUser ? msg.toJid : msg.fromJid;
                    Buddy* buddy = [self getOrCreateBuddy:buddyJid];
                    
                    Message* exactMatch = [results filter:^BOOL(Message* m) {
                        return [m.text isEqual:msg.body] &&
                        m.fromUser == fromUser &&
                        [m.buddy.jid isEqual:buddyJid] &&
                        m.date == msg.date;
                    }].first;
                    
                    
                    Message* match = exactMatch;
                    
                    if (!exactMatch) {
                        match = [results filter:^BOOL(Message* m) {
                            return [m.text isEqual:msg.body] &&
                            m.fromUser == fromUser &&
                            [m.buddy.jid isEqual:buddyJid];
                        }].first;
                    }
                    
                    
                    if (match) {
                        DDLogVerbose(@"    found match, updating UID and (date)");
                        match.imapUID = [NSNumber numberWithLongLong:msg.uid];
                        match.date = msg.date;
                    } else {
                        
                        Message* newMsg = [NSEntityDescription insertNewObjectForEntityForName:@"Message"
                                                                        inManagedObjectContext:_moc];
                        
                        newMsg.text = msg.body;
                        newMsg.fromUser = fromUser;
                        newMsg.date = msg.date;
                        newMsg.imapUID = [NSNumber numberWithLongLong:msg.uid];
                        
                        newMsg.buddy = buddy;
                        
                        
                        
                        DDLogVerbose(@"    match not found, inserted new message: %@", newMsg);
                    }
                    
                    if (msgCount++ % 500 == 0) {
                        [_moc save:nil];
                        [_moc processPendingChanges];
                    }
                    
                    
                    if (msg.uid > latestUID)
                        latestUID = msg.uid;
                    
                    
                    //[_moc refreshObject:buddy mergeChanges:NO];  // dont do this before save
                }
            }
            [_moc save:nil];
            
            [_moc processPendingChanges];
            
            dispatch_async(_backendQueue, ^{
                if (latestUID > _cachedLatestUID) { // some messages were added
                    _cachedLatestUID = latestUID;
                    DDLogInfo(@"%u messages added, Fetching more", messages.count);
                    [self fetchLatest]; // fetch more
                }
            });
           
            
        } else {
            if (error)
                DDLogError(@"Error trying to fetch imap UUID: %@", error);
        }

    }];

}

- (void)onUserActivation {
    [self fetchLatest];
}

- (void)setOlderMessagesNeeded:(BOOL)olderMessagesNeeded {
    
}

- (NSNumber*)fetchEarliestUID {
    NSFetchRequest* fetchUID = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    fetchUID.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"imapUID" ascending:YES]];
    fetchUID.fetchLimit = 1;
    
    NSError* error = NULL;
    NSArray* results = [_moc executeFetchRequest:fetchUID error:&error];
    
    if (results.lastObject) {
        Message* msg = results.lastObject;
        return msg.imapUID;
        
    } else {
        if (error)
            DDLogError(@"Error trying to fetch imap UUID: %@", error);
        return nil;
    }
}

- (NSNumber*)fetchLatestUID {
    NSFetchRequest* fetchUID = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    fetchUID.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"imapUID" ascending:NO]];
    fetchUID.fetchLimit = 1;
    
    NSError* error = NULL;
    NSArray* results = [_moc executeFetchRequest:fetchUID error:&error];
    
    if (results.lastObject) {
        Message* msg = results.lastObject;
        return msg.imapUID;
        
    } else {
        if (error)
            DDLogError(@"Error trying to fetch imap UUID: %@", error);
        return nil;
    }
}
- (Buddy*)getOrCreateBuddy:(NSString*)jid {
    
    Buddy* buddy = [self fetchBuddyForJid:jid];
    
    if (!buddy) {
        buddy = [NSEntityDescription insertNewObjectForEntityForName:@"Buddy"
                                              inManagedObjectContext:_moc];
        buddy.jid = jid;
        buddy.active = NO;
        
        DDLogVerbose(@"Created inactive buddy: %@ to hold invisible messages", jid);
    }
    
    return buddy;
}

- (Buddy*)fetchBuddyForJid:(NSString*)jid {
    NSFetchRequest* fetchBuddy = [NSFetchRequest fetchRequestWithEntityName:@"Buddy"];
    fetchBuddy.predicate = [NSPredicate predicateWithFormat:@"jid == %@", jid.bareJid];
    
    NSError* error = NULL;
    NSArray* results = [_moc executeFetchRequest:fetchBuddy error:&error];
    
    if (results.lastObject)
        return results.lastObject;
    else {
        if (error)
            DDLogError(@"Error trying to fetch existing buddies: %@", error);
        return nil;
    }
}
@end
