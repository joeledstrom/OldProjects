//
//  CoreDataParentManager.h
//  GTell
//
//  Created by Joel Edström on 3/14/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataParentManager : NSObject
- (id)initWithObjectModel:(NSURL*)objectModel store:(NSURL*)store;
- (NSManagedObjectContext*)getChildContext;
- (NSManagedObjectContext*)getChildContextForMainThread;
- (void)asyncSave;
- (void)saveContextSync;
@end