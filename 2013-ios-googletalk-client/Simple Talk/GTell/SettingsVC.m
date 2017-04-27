//
//  SettingsVC.m
//  GTell
//
//  Created by Joel Edström on 3/22/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "SettingsVC.h"

@interface SettingsVC ()
@property (nonatomic, weak) IBOutlet UIImageView* statusView;
@property (nonatomic, weak) IBOutlet UIImageView* photoView;

@end

@implementation SettingsVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
   
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoTapped:)];
    
    [self.photoView addGestureRecognizer:tap];
    
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Sign Out" style:UIBarButtonItemStylePlain target:self action:nil];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
   
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIGraphicsBeginImageContextWithOptions(self.statusView.bounds.size, NO, 0.0);
        [[UIColor colorWithRed:0 green:195/255.0 blue:70/255.0 alpha:1] set];
        UIBezierPath* bezierPath = [UIBezierPath bezierPathWithOvalInRect:self.statusView.bounds];
        [bezierPath fill];
        
        UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.statusView.image = img;
            [self.statusView setNeedsDisplay];
        });
        
    });

}
- (void)photoTapped:(id)sender {
    
    //UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
    //imagePicker.delegate = self;
    //[self presentViewController:imagePicker animated:YES completion:nil];
    
    UIActionSheet* sheet = [[UIActionSheet alloc] init];
    [sheet addButtonWithTitle:@"Take Photo"];
    [sheet addButtonWithTitle:@"Existing..."];
    [sheet addButtonWithTitle:@"Cancel"];
    sheet.cancelButtonIndex = 2;
    [sheet showInView:self.view];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSLog(@"picked: %@", info);
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    NSLog(@"cancel");
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
