#import "CoreDataManager.h"
#import "LibrariesLocationsHoursViewController.h"
#import "LibrariesLocationsHoursDetailViewController.h"
#import "LibrariesLocationsHours.h"
#import "MITLoadingActivityView.h"
#import "MITUIConstants.h"

@implementation LibrariesLocationsHoursViewController
@synthesize loadingView;
@synthesize libraries;
@synthesize request;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    self.loadingView = nil;
    self.request = nil;
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
    [self.tableView applyStandardColors];
    [self.tableView applyStandardCellHeight];
    self.title = @"Locations & Hours";
    
    if (!self.libraries) {
        self.loadingView = [[[MITLoadingActivityView alloc] initWithFrame:self.view.bounds] autorelease];
        self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:self.loadingView];
        
        self.request = [[[MITMobileWebAPI alloc] initWithModule:@"libraries" command:@"locations" parameters:nil] autorelease];
        self.request.jsonDelegate = self;
        [self.request start];
    }
    
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.loadingView = nil;
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
    if (self.libraries) {
        return 1;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.libraries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        [cell applyStandardFonts];
    }
    
    LibrariesLocationsHours *library = [self.libraries objectAtIndex:indexPath.row];
    cell.textLabel.text = library.title;
    cell.detailTextLabel.text = library.status;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LibrariesLocationsHoursDetailViewController *detailController = [[LibrariesLocationsHoursDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
    detailController.library = [self.libraries objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:detailController animated:YES];
    [detailController release];
}

#pragma mark - JSONLoaded delegate methods

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)jsonObject {
    [LibrariesLocationsHours removeAllLibraries];
     
    NSArray *libraryItems = jsonObject;
    NSMutableArray *mutableLibraries = [NSMutableArray arrayWithCapacity:libraryItems.count];
    for (NSDictionary *libraryItem in libraryItems) {
        LibrariesLocationsHours *library = [LibrariesLocationsHours libraryWithDict:libraryItem];
        [mutableLibraries addObject:library];
    }
    [CoreDataManager saveData];
    [self.loadingView removeFromSuperview];
    self.libraries = mutableLibraries;
    [self.tableView reloadData];
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
    return YES;
}

- (id<UIAlertViewDelegate>)request:(MITMobileWebAPI *)request alertViewDelegateForError:(NSError *)error {
    return self;
}

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.navigationController.visibleViewController == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
@end
