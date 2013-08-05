#import "CalendarCategoriesViewController.h"
#import "MobileRequestOperation.h"
#import "UIKit+MITAdditions.h"

@implementation CalendarCategoriesViewController
- (void)viewDidLoad {
    [super viewDidLoad];

	self.categories = nil;
    
    MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:@"calendar"
                                                                              command:@"categories"
                                                                           parameters:nil];
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (error)
        {
            DDLogVerbose(@"request failed");
        }
        else if ([jsonResult isKindOfClass:[NSArray class]])
        {
            self.categories = jsonResult;
            [self.tableView reloadData];
        }
    };
    
    [[NSOperationQueue mainQueue] addOperation:request];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark Table view methods
// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.categories count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
	NSDictionary *category = self.categories[indexPath.row];
	cell.textLabel.text = category[@"name"];
	
    return cell;
}
@end

