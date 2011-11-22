#import "CoreDataManager.h"
#import "LibrariesLocationsHoursViewController.h"
#import "LibrariesLocationsHoursDetailViewController.h"
#import "LibrariesLocationsHours.h"
#import "MITLoadingActivityView.h"
#import "MITUIConstants.h"

#define PADDING 10
#define CELL_TITLE_TAG 1
#define CELL_SUBTITLE_TAG 2
#define CELL_LABEL_WIDTH 250

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
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(PADDING, PADDING, CELL_LABEL_WIDTH, 0)] autorelease];
        titleLabel.tag = CELL_TITLE_TAG;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
        titleLabel.textColor = CELL_STANDARD_FONT_COLOR;
        titleLabel.highlightedTextColor = [UIColor whiteColor];
        titleLabel.tag = CELL_TITLE_TAG;
        titleLabel.numberOfLines = 0;
        
        UIFont *subtitleFont = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
        UILabel *subtitleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(PADDING, PADDING, CELL_LABEL_WIDTH, subtitleFont.lineHeight)] autorelease];
        subtitleLabel.backgroundColor = [UIColor clearColor];
        subtitleLabel.font = subtitleFont;
        subtitleLabel.textColor = CELL_DETAIL_FONT_COLOR;
        subtitleLabel.highlightedTextColor = [UIColor whiteColor];
        subtitleLabel.tag = CELL_SUBTITLE_TAG;
        
        [cell.contentView addSubview:titleLabel];
        [cell.contentView addSubview:subtitleLabel];
    }
    
    UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:CELL_TITLE_TAG];
    UILabel *subtitleLabel = (UILabel *)[cell.contentView viewWithTag:CELL_SUBTITLE_TAG];    
    
    LibrariesLocationsHours *library = [self.libraries objectAtIndex:indexPath.row];
    titleLabel.text = library.title;
    subtitleLabel.text = library.status;
    
    CGRect titleFrame = titleLabel.frame;
    titleFrame.size.height = [library.title sizeWithFont:[UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE]
                                       constrainedToSize:CGSizeMake(CELL_LABEL_WIDTH, 500)].height;
    titleLabel.frame = titleFrame;
    CGRect subtitleFrame = subtitleLabel.frame;
    subtitleFrame.origin.y = titleFrame.origin.y + titleFrame.size.height;
    subtitleLabel.frame = subtitleFrame;
    
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    LibrariesLocationsHours *library = [self.libraries objectAtIndex:indexPath.row];
    CGSize titleSize = [library.title sizeWithFont:[UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE] 
                                 constrainedToSize:CGSizeMake(CELL_LABEL_WIDTH, 500)];
    return titleSize.height + 2 * PADDING + [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE].lineHeight;
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
