#import "CalendarCategoriesViewController.h"
#import "MobileRequestOperation.h"
#import "UIKit+MITAdditions.h"

@implementation CalendarCategoriesViewController

@synthesize categories;

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

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.categories != nil) {
		return [self.categories count];
	}
	return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
	NSDictionary *category = [self.categories objectAtIndex:indexPath.row];
    // Set up the cell...
	cell.textLabel.text = [category objectForKey:@"name"];
	
    return cell;
}
@end

