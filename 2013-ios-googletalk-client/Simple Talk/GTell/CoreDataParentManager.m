//
//  CoreDataParentManager.m
//  GTell
//
//  Created by Joel Edström on 3/14/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "CoreDataParentManager.h"
#import <CoreData/CoreData.h>

@implementation CoreDataParentManager {
    NSManagedObjectContext* _context;
    NSManagedObjectContext* _mainThreadContext;
    NSPersistentStoreCoordinator* _storeCordinator;
    NSURL* _modelUrl;
    NSURL* _storeUrl;
}


- (id)initWithObjectModel:(NSURL*)objectModel store:(NSURL*)store {
    
    self = [super init];
    if (self) {
        _modelUrl = objectModel;
        _storeUrl = store;
    }
    return self;
}



- (void)asyncSave {
    [self saveContextAsync];
}


- (NSManagedObjectContext*)getChildContext {
    return [self internalGetChildContext:NSPrivateQueueConcurrencyType];
}

- (NSManagedObjectContext*)getChildContextForMainThread {
    return _mainThreadContext ?: [self internalGetChildContext:NSMainQueueConcurrencyType];
}


- (NSManagedObjectContext*)internalGetChildContext:(NSManagedObjectContextConcurrencyType)type {
    if (!_context)
        [self setup];
    
    NSManagedObjectContext* c = [[NSManagedObjectContext alloc] initWithConcurrencyType:type];
    
    c.parentContext = _context;
    c.undoManager = nil;
    
    return c;
}


- (BOOL)setupStoreCordinator {
    NSManagedObjectModel* model = [[NSManagedObjectModel alloc] initWithContentsOfURL:_modelUrl];
    
    _storeCordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    NSError* error = nil;
    
    if (![_storeCordinator addPersistentStoreWithType:NSSQLiteStoreType
                                        configuration:nil URL:_storeUrl
                                              options:nil
                                                error:&error]) {
        NSLog(@"Error adding persistant store: %@, %@", error, [error userInfo]);
        return NO;
    }
    
    return YES;
}
- (void)setup {
    
    if (![self setupStoreCordinator]) {
        NSLog(@"Deleting it, and trying again");
        [[NSFileManager defaultManager] removeItemAtURL:_storeUrl error:nil];
        if (![self setupStoreCordinator]) {
            NSLog(@"Still doesn't work, critical failure!");
            abort();
        }
    }
    
       
    _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    _context.persistentStoreCoordinator = _storeCordinator;
    _context.undoManager = nil;
}

- (void)saveContextAsync      // TODO: add background processing "wake lock"
{
    [_context performBlock:^{
        NSError *error = nil;
        if (_context != nil) {
            if ([_context hasChanges] && ![_context save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }
    }];
    
}

- (void)saveContextSync {
    [_context performBlockAndWait:^{
        NSError *error = nil;
        if (_context != nil) {
            if ([_context hasChanges] && ![_context save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }
    }];
}

@end
