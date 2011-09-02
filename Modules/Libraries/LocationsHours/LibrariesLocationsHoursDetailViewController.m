#import "LibrariesLocationsHoursDetailViewController.h"
#import "CoreDataManager.h"

#define TITLE_ROW 0
#define LOADING_STATUS_ROW 1

@implementation LibrariesLocationsHoursDetailViewController
@synthesize library;
@synthesize librariesDetailStatus;
@synthesize request;

- (void)dealloc
{
    self.request = nil;
    self.library = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Detail";

    if (![self.library hasDetails]) {
        self.librariesDetailStatus = LibrariesDetailStatusLoading;
        
        NSDictionary *params = [NSDictionary dictionaryWithObject:self.library.title forKey:@"library"];
        self.request = [[[MITMobileWebAPI alloc] initWithModule:@"libraries" command:@"locationDetail" parameters:params] autorelease];
        self.request.jsonDelegate = self;
        [self.request start];
    } else {
        self.librariesDetailStatus = LibrariesDetailStatusLoaded;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.librariesDetailStatus == LibrariesDetailStatusLoaded) {
        return 1;
    } else {
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = nil;
    UITableViewCell *cell;
    switch (indexPath.row) {
        case TITLE_ROW:
            cellIdentifier = @"title";
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier]autorelease];
                cell.selectionStyle = UITableViewCellEditingStyleNone;
            }
            cell.textLabel.text = self.library.title;
            break;
            
        case LOADING_STATUS_ROW:
            cellIdentifier = @"loadingStatus";
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier]autorelease];
                cell.selectionStyle = UITableViewCellEditingStyleNone;
            }
            
            if (self.librariesDetailStatus == LibrariesDetailStatusLoading) {
                cell.textLabel.text = @"Loading...";
            } else if (self.librariesDetailStatus == LibrariesDetailStatusLoadingFailed) {
                cell.textLabel.text = @"Failed loading details";
            }
            
        default:
            break;
    }
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

#pragma mark - JSONLoaded delegate methods

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject {
    [self.library updateDetailsWithDict:JSONObject];
    [CoreDataManager saveData];
    self.librariesDetailStatus = LibrariesDetailStatusLoaded;
    [self.tableView reloadData];
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
    return NO;
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
    self.librariesDetailStatus = LibrariesDetailStatusLoadingFailed;
    [self.tableView reloadData];
}



@end
