#import "CalendarCategoriesViewController.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "UIKit+MITAdditions.h"

@implementation CalendarCategoriesViewController
- (void)viewDidLoad {
    [super viewDidLoad];

	self.categories = nil;

    NSURLRequest *request = [NSURLRequest requestForModule:@"calendar" command:@"categories" parameters:nil];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSArray *responseObject) {
        if ([responseObject isKindOfClass:[NSArray class]]) {
            self.categories = responseObject;
            [self.tableView reloadData];
        } else {
            DDLogVerbose(@"calendar categories request failed, expected an NSArray but got a %@", NSStringFromClass([responseObject class]));
        }
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        if (error) {
            DDLogVerbose(@"calendar categories request failed: %@", error);
        }
    }];
    
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
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

