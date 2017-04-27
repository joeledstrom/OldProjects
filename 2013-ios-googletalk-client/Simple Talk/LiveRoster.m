//
//  LiveRoster.m
//  Simple Talk
//
//  Created by Joel Edström on 3/30/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "LiveRoster.h"
#import "MulticastDelegate.h"
#import <CoreData/CoreData.h>
#import "DDLog.h"
#import "Utils.h"
#import "Buddy.h"


static const int ddLogLevel = LOG_LEVEL_INFO;


@implementation LiveRosterBuddy
- (id)initWithJid:(NSString*)jid
             name:(NSString*)name
          picture:(UIImage*)picture
           status:(LiveRosterBuddyStatus)status
       statusText:(NSString*)statusText;
{
    self = [super init];
    if (self) {
        _jid = jid;
        _name = name;
        _picture = picture;
        _status = status;
        _statusText = statusText;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"LiveRosterBuddy(jid = %@, name = %@, status = %d, statusText = %@)", _jid, _name, _status, _statusText];
}

@end

@interface LiveRoster () <NSFetchedResultsControllerDelegate>

@end

@implementation LiveRoster {
    NSManagedObjectContext* _moc;
    dispatch_queue_t _backendQueue;
    MulticastDelegate* _delegates;
    NSArray* _roster;
    NSFetchedResultsController* _rosterFetch;
    NSMutableDictionary* _xmppResourcesByJid;
    BOOL _buildRosterScheduled;
    NSTimeInterval _timeOfLastBuildRoster;
}

- (void)addDelegate:(id <LiveRosterDelegate>)delegate {
    [_delegates addDelegate:delegate];
    dispatch_async(_backendQueue, ^{
        [self refresh];
    });
}

- (id)initWithManagedContext:(NSManagedObjectContext*)moc backendQueue:(dispatch_queue_t)queue
{
    self = [super init];
    if (self) {
        _moc = moc;
        _backendQueue = queue;
        _delegates = [MulticastDelegate new];
        _xmppResourcesByJid = [NSMutableDictionary new];
    }
    return self;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    DDLogVerbose(@"controllerDidChangeContent");
    dispatch_async(_backendQueue, ^{
        [self refresh];
    });
}

- (void)setupFetchedResultsController {
    [_moc performBlockAndWait:^{
        NSFetchRequest* req = [NSFetchRequest fetchRequestWithEntityName:@"Buddy"];
        req.predicate = [NSPredicate predicateWithFormat:@"active == YES"];
        req.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"jid" ascending:YES]];
        _rosterFetch = [[NSFetchedResultsController alloc] initWithFetchRequest:req managedObjectContext:_moc sectionNameKeyPath:nil cacheName:nil];
        _rosterFetch.delegate = self;
        [_rosterFetch performFetch:nil];
    }];
   
}

- (void)refresh {
    if (!_rosterFetch)
        [self setupFetchedResultsController];
    
    
    if (_buildRosterScheduled) {
        DDLogVerbose(@"blocking buildRoster, due to rate limit");
        return;
    }
    
    
    // more than 2 seconds passed since last roster build
    if (_timeOfLastBuildRoster + 2 < [[NSDate date] timeIntervalSince1970] ) {
        DDLogVerbose(@"immediate call to buildRoster, > 2 sec since last time");
        [self buildRoster];
    } else  {
        DDLogVerbose(@"buildRoster scheduled in 2 secs");
        _buildRosterScheduled = YES;
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, _backendQueue, ^(void){
            [self buildRoster];
        });
    }
    
}

- (void)buildRoster {
    DDLogVerbose(@"buildRoster");
    assert(dispatch_get_current_queue() == _backendQueue);
    
    
    
    // sort by status
    NSSortDescriptor* status = [NSSortDescriptor sortDescriptorWithKey:@"status" ascending:NO];
    NSArray* sortDescriptors = @[status];
    
    
    // build and sort roster
    NSArray* newRoster = [[_rosterFetch.fetchedObjects map:^id(Buddy* b) {
        
        UIImage* pic = [UIImage imageWithData:b.picture];
        
        
        NSString* statusText = @"";
        LiveRosterBuddyStatus status = kLiveRosterBuddyStatusOFFLINE;
        
        NSDictionary* resources = _xmppResourcesByJid[b.jid];
        
        // find the "best/highest" status
        for (XMPPResource2* r in resources.allValues) {
            
            LiveRosterBuddyStatus s = kLiveRosterBuddyStatusAVAILABLE;
            if ([r.show isEqual:@"dnd"]) {
                s = kLiveRosterBuddyStatusDND;
            } else if ([r.show isEqual:@"away"]) {
                s = kLiveRosterBuddyStatusIDLE;
            }
            
            if (s >= status) {
                status = s;
                statusText = r.status;
            }
        }
        
        DDLogVerbose(@"status: %d for %@", status, b.jid);
        
        
        return [[LiveRosterBuddy alloc] initWithJid:b.jid name:b.name picture:pic status:status statusText:statusText];
        
    }] sortedArrayUsingDescriptors:sortDescriptors];
    
    
    [self updateRoster:newRoster];
    
    _timeOfLastBuildRoster = [[NSDate date] timeIntervalSince1970];
    _buildRosterScheduled = NO;
}

- (NSDictionary*)buildJidToIndexFor:(NSArray*)roster {
    NSMutableDictionary* jidToIndex = [NSMutableDictionary new];
    
    [roster enumerateObjectsUsingBlock:^(LiveRosterBuddy* b, NSUInteger idx, BOOL *stop) {
        jidToIndex[b.jid] = @(idx);
    }];
    
    return jidToIndex;
}

- (void)updateRoster:(NSArray*)newRoster {
    
    NSMutableArray* added = [NSMutableArray new];
    NSMutableArray* changed = [NSMutableArray new];
    NSMutableArray* movedFrom = [NSMutableArray new];
    NSMutableArray* movedTo = [NSMutableArray new];
    NSMutableArray* removed = [NSMutableArray new];

    NSDictionary* jidToOldIndex = [self buildJidToIndexFor:_roster];
    NSDictionary* jidToNewIndex = [self buildJidToIndexFor:newRoster];
    
    
    
    [newRoster enumerateObjectsUsingBlock:^(LiveRosterBuddy* newBuddy, NSUInteger idx, BOOL *stop) {
        NSNumber* oldIndexNumber = jidToOldIndex[newBuddy.jid];
        NSUInteger oldIndex = [oldIndexNumber unsignedIntegerValue];
        
        if (oldIndexNumber == nil) {
            [added addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
        } else if (oldIndex != idx) {
            [movedFrom addObject:[NSIndexPath indexPathForRow:oldIndex inSection:0]];
            [movedTo addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
        } // else same position in newRoster
        
        //if (oldIndexNumber) {  // existed in the oldRoster
        else {
            LiveRosterBuddy* oldBuddy = _roster[oldIndex];
            
            
            if (!([newBuddy.name isEqual:oldBuddy.name] &&
                  [newBuddy.statusText isEqual:oldBuddy.statusText] &&
                  newBuddy.status == oldBuddy.status &&
                  newBuddy.picture != nil &&
                  oldBuddy.picture != nil &&
                  [UIImagePNGRepresentation(newBuddy.picture)          // TODO: slow
                   isEqual:UIImagePNGRepresentation(oldBuddy.picture)])) {
                
                
                [changed addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
            }
            
        }
        
    }];
    
    [_roster enumerateObjectsUsingBlock:^(LiveRosterBuddy* oldBuddy, NSUInteger idx, BOOL *stop) {
        if (jidToNewIndex[oldBuddy.jid] == nil) {
            [removed addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
        }
    }];
    
    
    _roster = newRoster;
    
    
    [_delegates iterateDelegatesOnQueue:dispatch_get_main_queue() withBlock:^(id <LiveRosterDelegate> delegate) {
        [delegate rosterChangedTo:newRoster addedRowIndexPaths:added changedRowIndexPaths:changed movedRowIndexPathsFrom:movedFrom toIndexPaths:movedTo removedRowIndexPaths:removed];
    }];
}


- (void)setResource:(XMPPResource2*)resource {
    if (!_xmppResourcesByJid[resource.jid])
        _xmppResourcesByJid[resource.jid] = [NSMutableDictionary new];
    
    NSMutableDictionary* resourcesByName = _xmppResourcesByJid[resource.jid];
    
    resourcesByName[resource.name] = resource;
    
    NSLog(@"setResource %@", _xmppResourcesByJid);

    
    [self refresh];
}
- (void)removeResourceForJid:(NSString*)jid withName:(NSString*)resourceName {
    NSMutableDictionary* resourcesByName = _xmppResourcesByJid[jid];
    [resourcesByName removeObjectForKey:resourceName];
    
    [self refresh];
}
@end
