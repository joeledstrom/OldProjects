//
//  ChatVC.m
//  GTell
//
//  Created by Joel Edström on 3/7/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "ChatVC.h"
#import "MessageCell.h"
#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import "Message.h"
#import "Buddy.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;




@interface ChatVC () <NSFetchedResultsControllerDelegate>

@end

@implementation ChatVC {
    NSFetchedResultsController* _fetchedResultsController;
    UITextView* _sampleTextView;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _sampleTextView = [self createChatTextView];
    }
    return self;
}



- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
       
    NSIndexPath* ip = [NSIndexPath indexPathForRow:[self tableView:self.tableView numberOfRowsInSection:0]-1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:ip atScrollPosition: UITableViewScrollPositionTop animated: NO];
    
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.buddy.name.length > 0 ? self.buddy.name : self.buddy.jid;
    
    
    //[self.tableView registerNib:[UINib nibWithNibName:@"MessageSentCell" bundle:nil] forCellReuseIdentifier:@"sentCell"];
    
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    
    NSManagedObjectContext* moc = [appDelegate.parentManager getChildContextForMainThread];
    
    
    Buddy* b = [self fetchBuddyForJid:self.buddy.jid moc:moc];
    
    if (b) {
        NSFetchRequest* req = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
        req.predicate = [NSPredicate predicateWithFormat:@"buddy == %@", b];
        
        req.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:req managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
        _fetchedResultsController.delegate = self;
        
        [_fetchedResultsController performFetch:nil];
        
        
        NSLog(@"rows: %d", [self tableView:self.tableView numberOfRowsInSection:0]);
        
        

    }
}


- (Buddy*)fetchBuddyForJid:(NSString*)jid moc:(NSManagedObjectContext*)moc {
    NSFetchRequest* fetchBuddy = [NSFetchRequest fetchRequestWithEntityName:@"Buddy"];
    fetchBuddy.predicate = [NSPredicate predicateWithFormat:@"jid == %@", jid];
    
    NSError* error = NULL;
    NSArray* results = [moc executeFetchRequest:fetchBuddy error:&error];
    
    if (results.lastObject)
        return results.lastObject;
    else {
        if (error)
            DDLogError(@"Error trying to fetch existing buddies: %@", error);
        return nil;
    }
}
/*

- (NSIndexPath*)dataSourceIndexFromTableIndex:(NSIndexPath*)ip {
    id  sectionInfo = [[_fetchedResultsController sections] objectAtIndex:0];

    int64_t count = [sectionInfo numberOfObjects];
    return [NSIndexPath indexPathForRow:(count-ip.row-1) inSection:0];
}

- (NSIndexPath*)tableIndexFromDataSourceIndex:(NSIndexPath*)ip {
    id  sectionInfo = [[_fetchedResultsController sections] objectAtIndex:0];
    
    int64_t count = [sectionInfo numberOfObjects];
    return [NSIndexPath indexPathForRow:(count-ip.row-1) inSection:0];
}*/

- (UITextView*)createChatTextView {
    UITextView *tv = [[UITextView alloc] initWithFrame:CGRectZero];
    tv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tv.scrollEnabled = NO;
    tv.editable = NO;
    tv.dataDetectorTypes = UIDataDetectorTypeAll;
    return tv;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell* m = [self.tableView dequeueReusableCellWithIdentifier:@"sentCell"];
    
    
    if (!m) {
        m = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"sentCell"];
        UITextView *tv = [self createChatTextView];
        tv.frame = CGRectInset(m.bounds, 5, 5);
        [m.contentView addSubview:tv];
        //NSLog(@"%d", [m.contentView.subviews indexOfObject:tv]);
    }
        
    
    NSIndexPath* ip = indexPath; //[self dataSourceIndexFromTableIndex:indexPath];
    
    Message* msg = [_fetchedResultsController objectAtIndexPath:ip];
    
    //m.textLabel.text = msg.text;
    UITextView* tv = m.contentView.subviews[0];
    
    tv.text = msg.text;
    
    
    return m;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    
    NSIndexPath* ip = indexPath; //[self dataSourceIndexFromTableIndex:indexPath];
    Message* msg = [_fetchedResultsController objectAtIndexPath:ip];
    NSString* s = msg.text;
    
    
    CGSize size = [s sizeWithFont:_sampleTextView.font
                constrainedToSize:CGSizeMake(tableView.bounds.size.width - 10 /*- 72*/, CGFLOAT_MAX)];
    
    //NSLog(@"%f", size.height);

    return size.height+10;
    //return MAX(73, size.height);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id  sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];

}

/*
// copy/paste
- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    //NSLog(@"%@", NSStringFromSelector(action));
    
    if ([NSStringFromSelector(action) isEqual:@"copy:"])
        return YES;
    
    return NO;
}
- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    XMPPMessage* m = _messages[indexPath.row];
    [[UIPasteboard generalPasteboard] setString:m.body];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}*/


// fetchedResults delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    
    //indexPath = [self tableIndexFromDataSourceIndex:indexPath];
    //newIndexPath = [self tableIndexFromDataSourceIndex:newIndexPath];
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            /*
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;*/
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}





- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    NSLog(@"KAKA");

    [self.tableView endUpdates];
}
@end


