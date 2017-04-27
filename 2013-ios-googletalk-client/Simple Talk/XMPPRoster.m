//
//  XMPPRoster.m
//  GTell
//
//  Created by Joel Edström on 3/21/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "XMPPRoster.h"
#import "XMPPParser.h"
#import "XMLNode+XMPP.h"
#import "Utils.h"

// TODO:
// - handle type = 'unavailable' presence stanzas => remove resource
// - add show/status to XMPPResource (make it per resource)


@implementation XMPPResource
- (id)initWithName:(NSString*)name priority:(NSInteger)priority;
{
    self = [super init];
    if (self) {
        _name = name;
        _priority = priority;
    }
    return self;
}
@end

@implementation XMPPBuddy
- (id)initWithJid:(NSString*)jid
             name:(NSString*)name
        resources:(NSDictionary*)resources
     subscription:(XMPPSubscription)subscription
             show:(NSString*)show
           status:(NSString*)status
{
    self = [super init];
    if (self) {
        _jid = jid;
        _name = name;
        _resources = resources;
        _subscription = subscription;
        _show = show;
        _status = status;
    }
    return self;
}
- (NSString *)description {
    NSString* res = [_resources.allValues foldLeft:@"" with:^id(NSString* a, XMPPResource* x) {
        return [a stringByAppendingString:[NSString stringWithFormat:@"(name = %@, prio = %d)", x.name, x.priority]];
    }];
    return [NSString stringWithFormat:@"XMPPBuddy(jid = %@, name = %@, resources = [%@], subscription = %d, show = %@, status = %@)", _jid, _name, res, _subscription, _show, _status];
}
- (XMPPBuddy*)mergeWith:(XMPPBuddy*)other {
    
    if (![other.jid isEqual:self.jid])
        NSLog(@"Weird bug");
    
    NSString* name = other.name ?: self.name;
    
    NSMutableDictionary* resources = [NSMutableDictionary new];
    
    if (self.resources)
        [resources addEntriesFromDictionary:self.resources];
    
    if (other.resources)
        [resources addEntriesFromDictionary:other.resources];
    
    if (resources.count == 0) {
        resources = nil;
    }
    
    XMPPSubscription sub = other.subscription != XMPPSubscriptionUNDEFINED ? other.subscription : self.subscription;
    NSString* status = other.status ?: self.status;
    NSString* show = other.show ?: self.show;
    
    return [[XMPPBuddy alloc] initWithJid:other.jid name:name resources:resources
                             subscription:sub show:show status:status];
    
}
@end

@implementation XMPPRoster {
    XMPPStreamRemote* _remote;
    NSDictionary* _roster;
    NSMutableArray* _incPresenceQueue;
    __weak id <XMPPRosterDelegate> _delegate;
}
- (id)initWithDelegate:(id <XMPPRosterDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}
- (void)startWithRemote:(XMPPStreamRemote*)remote {
    _remote = remote;
}
- (void)moduleEventRecevied:(NSString *)event {
    static NSString* rosterRequest = @"<iq type='get' id='roster_1'><query xmlns='jabber:iq:roster'/></iq>";
    
    if ([event isEqual:kModuleEventAuthenticationComplete]) {
        [_remote sendData:rosterRequest];
    }
    
}
- (void)presenceReceived:(XMLNode*)presence {
    if (presence.type == nil) {
        NSString* fromJid = presence.attributes[@"from"];
        NSString* show = [presence childWithName:@"show"].text ?: @"";
        NSString* status = [presence childWithName:@"status"].text ?: @"";
        
        NSString* bare = fromJid.bareJid;
        NSString* resource = fromJid.jidResource;
        NSInteger priority = [presence childWithName:@"priority"].text.integerValue;
        
        XMPPResource* res = [[XMPPResource alloc] initWithName:resource priority:priority];
        
        if (bare && resource) {
            XMPPBuddy* n = [[XMPPBuddy alloc] initWithJid:bare name:nil
                                                resources:@{resource: res}
                                             subscription:XMPPSubscriptionUNDEFINED
                                      show:show status:status];
            
            
            if (!_incPresenceQueue)
                _incPresenceQueue = [NSMutableArray new];
            
            [_incPresenceQueue addObject:n];
            
            if (_incPresenceQueue.count > 20)
                [self mergeRoster:nil];
            else {
                double delayInSeconds = 1.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, _remote.xmppQueue , ^(void){
                    [self mergeRoster:nil];
                });
            }
        }
        
        

    }
}

- (void)iqReceived:(XMLNode*)iq {
    if ([iq.type isEqual:@"result"] || [iq.type isEqual:@"set"]) {
        XMLNode* query = [iq childWithName:@"query"];
        if ([query.attributes[@"xmlns"] isEqual:@"jabber:iq:roster"]) {
            NSArray* newRosterItems = [[query childrenWithName:@"item"] map:^id(XMLNode* x) {
                NSString* sub = x.attributes[@"subscription"];
                NSString* name = x.attributes[@"name"];
                
                XMPPSubscription s = XMPPSubscriptionNONE;
                
                if ([sub isEqual:@"both"]) {
                    s = XMPPSubscriptionBOTH;
                } else if ([sub isEqual:@"to"]) {
                    s = XMPPSubscriptionTO;
                } else if ([sub isEqual:@"from"]) {
                    s = XMPPSubscriptionFROM;
                } else if ([sub isEqual:@"remove"]) {
                    s = XMPPSubscriptionREMOVE;
                }
                
                if (!x.attributes[@"jid"])
                    return nil;
                
                
                
                return [[XMPPBuddy alloc] initWithJid:x.attributes[@"jid"] name:name
                                            resources:nil subscription:s
                                                 show:nil status:nil];
            }];
            
            [self mergeRoster:newRosterItems];
        }
    }
    
}

- (void)mergeRoster:(NSArray*)newRosterItems {
    NSMutableArray* added = [NSMutableArray new];
    NSMutableArray* changed = [NSMutableArray new];
    NSMutableArray* removed = [NSMutableArray new];
    
    if (!newRosterItems && _incPresenceQueue.count == 0)
        return;
    
    
    NSMutableDictionary* newRoster = [NSMutableDictionary new];
    if (_roster)
        [newRoster addEntriesFromDictionary:_roster];
    
    
    if (newRosterItems) {
        for (XMPPBuddy* b in newRosterItems) {
            if (_roster[b.jid] == nil) {
                newRoster[b.jid] = b;
                [added addObject:b.jid];
            } else if (b.subscription == XMPPSubscriptionREMOVE) {
                [newRoster removeObjectForKey:b.jid];
                [removed addObject:b.jid];
                
            } else if (_roster[b.jid]) {
                XMPPBuddy* old = _roster[b.jid];
                XMPPBuddy* changedBuddy = [old mergeWith:b];
                
                if (changedBuddy) {
                    [changed addObject:b.jid];
                    newRoster[b.jid] = changedBuddy;
                }
            }
        }
    }
    
    if (!newRosterItems && _roster) {   // handle incPresenceQueue
        NSMutableDictionary* changedBuddies = [NSMutableDictionary new];
        
        for (XMPPBuddy* b in _incPresenceQueue) {
            XMPPBuddy* old = changedBuddies[b.jid] ?: _roster[b.jid];  //prefer already changed buddies
            XMPPBuddy* changedBuddy = [old mergeWith:b];
                
            if (changedBuddy) {
                if (![changed containsObject:b.jid])
                    [changed addObject:b.jid];
                
                changedBuddies[b.jid] = changedBuddy;
            }
            
        }
        [newRoster addEntriesFromDictionary:changedBuddies];
        [_incPresenceQueue removeAllObjects];
    } 
    
    
    
    _roster = [newRoster copy];
    
    dispatch_async(_remote.delegateQueue, ^{
        [_delegate rosterChangedTo:_roster addedJids:added changedJids:changed removedJids:removed];
    });
    
}
@end


