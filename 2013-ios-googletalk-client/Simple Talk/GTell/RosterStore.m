//
//  RosterCacher.m
//  Simple Talk
//
//  Created by Joel Edström on 3/30/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "RosterStore.h"
#import "DDLog.h"
#import <CoreData/CoreData.h>
#import "Buddy.h"
#import "XMLNode.h"
#import "Base64.h"
#include <CommonCrypto/CommonDigest.h>

static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation RosterStore {
    NSManagedObjectContext* _moc;
    XMPPvCard* _vcard;
    NSMutableSet* _requestedVcardThisSessionJids;
    dispatch_queue_t _backendQueue;
}
- (id)initWithManagedContext:(NSManagedObjectContext*)moc backendQueue:(dispatch_queue_t)queue
{
    self = [super init];
    if (self) {
        _moc = moc;
        _requestedVcardThisSessionJids = [NSMutableSet new];
        _backendQueue = queue;
    }
    return self;
}


- (void)setBuddy:(XMPPBuddy2*)xmppBuddy {
    
    [_moc performBlock:^{
        DDLogVerbose(@"Set Buddy (%@, %@)", xmppBuddy.jid, xmppBuddy.name);
        
        Buddy* buddy = [self fetchBuddyForJid:xmppBuddy.jid];
        
        if (!buddy) {
            buddy = [NSEntityDescription insertNewObjectForEntityForName:@"Buddy"
                                                  inManagedObjectContext:_moc];
            buddy.jid = xmppBuddy.jid;
            
            [_vcard fetchVCardForJid:buddy.jid];
        }
        
        
        
        buddy.name = xmppBuddy.name;
        buddy.active = YES;
        
        BuddySubscription s = kBuddySubscriptionNONE;
        
        if ([xmppBuddy.subscription isEqual:@"both"]) {
            s = kBuddySubscriptionBOTH;
        } else if ([xmppBuddy.subscription isEqual:@"to"]) {
            s = kBuddySubscriptionTO;
        } else if ([xmppBuddy.subscription isEqual:@"from"]) {
            s = kBuddySubscriptionFROM;
        }
        
        buddy.subscription = s;
        
        [_moc save:nil];
    }];
        
    
}
- (void)removeBuddyWithJid:(NSString*)jid {
    
    [_moc performBlock:^{
        DDLogVerbose(@"Remove Buddy %@", jid);
        Buddy* buddy = [self fetchBuddyForJid:jid];
        buddy.active = NO;
        [_moc save:nil];
    }];
}

- (Buddy*)fetchBuddyForJid:(NSString*)jid {
    NSFetchRequest* fetchBuddy = [NSFetchRequest fetchRequestWithEntityName:@"Buddy"];
    fetchBuddy.predicate = [NSPredicate predicateWithFormat:@"jid == %@", jid];
    
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

- (void)receivedVcard:(XMLNode *)vCard forJid:(NSString *)jid {
    [_moc performBlock:^{
        DDLogVerbose(@"Recevied VCard for %@", jid);
        
        Buddy* buddy = [self fetchBuddyForJid:jid];
        NSString* type = [[vCard childWithName:@"PHOTO"] childWithName:@"TYPE"].text;
        NSString* image = [[vCard childWithName:@"PHOTO"] childWithName:@"BINVAL"].text;
        
        NSData* imageData = [image dataFromBase64];
        
        if (imageData && type) {
            UIImage* parsedImg = [UIImage imageWithData:imageData];
            NSString* hash = [self calculateSHA1for:imageData];
            DDLogVerbose(@"VCard calculated hash: %@", hash);
            if (parsedImg && hash) {
                buddy.picture = imageData;
                buddy.pictureHash = hash;
            }
        } else {
            buddy.picture = nil;
            buddy.pictureHash = @"";
        }
        [_moc save:nil];
        
    }];
    
}
- (void)vCardUpdateForJid:(NSString*)jid receviedWithHash:(NSString*)hash {
        
    
    if ([_requestedVcardThisSessionJids containsObject:jid]) {
        DDLogVerbose(@"Hash may or may not match, but blocking further vcard requests this session");
        return;
    }
    
    [_moc performBlockAndWait:^{
        Buddy* buddy = [self fetchBuddyForJid:jid];
        
        NSString* pictureHash = buddy.pictureHash ?: @"";
        
        if (![pictureHash isEqual:hash]) {
            [_vcard fetchVCardForJid:jid];
            [_requestedVcardThisSessionJids addObject:jid];
            DDLogVerbose(@"Hash '%@' not matching for jid %@ - Requesting VCard refetch ", hash, jid);
        } else {
            DDLogVerbose(@"Hash '%@' matches for jid %@ - Already have latest Vcard picture", hash, jid);
        }
        [_moc save:nil];
    }];
}

- (void)setXMPPvCard:(XMPPvCard*)vcard {
    _vcard = vcard;
}

- (NSString*)calculateSHA1for:(NSData*)data {
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    
    if (CC_SHA1([data bytes], [data length], result)) {
        return [NSString  stringWithFormat:
                @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                result[0], result[1], result[2], result[3], result[4],
                result[5], result[6], result[7],
                result[8], result[9], result[10], result[11], result[12],
                result[13], result[14], result[15],
                result[16], result[17], result[18], result[19]];
    } else
        return nil;
}

@end
