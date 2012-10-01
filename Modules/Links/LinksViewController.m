
#import "LinksViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"
#import "MIT_MobileAppDelegate.h"

@interface LinksViewController ()

@property (nonatomic, retain) NSArray *linkResults;
@property (nonatomic, retain) MITLoadingActivityView *loadingView;
@property (nonatomic, retain) UILabel *errorLabel;

@end

static NSString * kLinksCacheFileName = @"links_cache.plist";

static NSString * kLinksKeySectionTitle = @"title";
static NSString * kLinksKeySectionLinks = @"links";
static NSString * kLinksKeyLinkUrl      = @"link";
static NSString * kLinksKeyLinkTitle    = @"name";

@implementation LinksViewController

@synthesize linkResults = _linkResults;
@synthesize loadingView = _loadingView;
@synthesize errorLabel = _errorLabel;

- (void) dealloc
{
    self.linkResults = nil;
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = @"Links";
    
    self.tableView = [[[UITableView alloc] initWithFrame:CGRectInset(self.view.bounds, 0, 0)
                                                   style:UITableViewStyleGrouped] autorelease];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView applyStandardColors];
    
    self.linkResults = [self cachedLinks];
    
    [self.tableView reloadData];
}

- (void) viewWillAppear:(BOOL)animated
{
    if (self.errorLabel) {
        [self.errorLabel removeFromSuperview];
        self.errorLabel = nil;
    }
    if (!self.linkResults) {
        [self showLoadingView];
    }
    self.tableView.userInteractionEnabled = YES;
    [self queryForLinks];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Loading View

- (void) showLoadingView {
    if (!self.loadingView) {
        self.tableView.userInteractionEnabled = NO;
        CGRect loadingFrame = self.tableView.bounds;
        self.loadingView = [[[MITLoadingActivityView alloc] initWithFrame:loadingFrame] autorelease];
        self.loadingView.usesBackgroundImage = NO;
        [self.view addSubview:self.loadingView];
    }
}

- (void) removeLoadingView {
    self.tableView.userInteractionEnabled = YES;
    [self.loadingView removeFromSuperview];
    self.loadingView = nil;
}

#pragma mark - Server/Cache Difference handling

- (void)updateLinksIfNeeded:(NSArray *)linksArray {
    if (![linksArray isEqualToArray:self.linkResults]) {     // remove ! to test case where cache is different from server response
        [self saveLinksToCache:linksArray];

        self.linkResults = @[];             // empty the table
        [self.tableView reloadData];        // reload the empty table  (necessary because using a UITableViewController)
        
        [self showLoadingView];
        
        double delayInSeconds = 0.5f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.linkResults = linksArray;
            [self.tableView reloadData];
            [self removeLoadingView];
        });
    }
}

#pragma mark - Connection
- (void)queryForLinks
{
    MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"links"
                                                                            command:nil
                                                                         parameters:nil];
    
    operation.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSError *error)
    {
        if (!error && jsonResult && [jsonResult isKindOfClass:[NSArray class]]) {
            [self updateLinksIfNeeded:(NSArray *)jsonResult];
        } else {
            // If there was an error or if the jsonResult is not an array as expected, ignore this call and rely on the cache.
            // If there is no cache, report the error.
            if (!self.linkResults || [self.linkResults count] == 0) {
                [self displayLoadingError];
            }
        }
        
    };

    [operation start];
}

- (void)displayLoadingError {
    [self removeLoadingView];
    CGFloat horizontalPadding = 20.0;
    CGRect frame = self.tableView.bounds;
    frame.origin.x = horizontalPadding;
    frame.size.width -= 2 * horizontalPadding;
    self.errorLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
    self.errorLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.errorLabel.backgroundColor = [UIColor clearColor];
    self.errorLabel.text = @"There was a problem loading the links. Please try again later.";
    self.errorLabel.textAlignment = UITextAlignmentCenter;
    self.errorLabel.shadowColor = [UIColor whiteColor];
    self.errorLabel.shadowOffset = CGSizeMake(0, 1);
    self.errorLabel.numberOfLines = 0;
    self.errorLabel.lineBreakMode = UILineBreakModeWordWrap;
    [self.tableView addSubview:self.errorLabel];
    
    self.tableView.userInteractionEnabled = NO;
}

#pragma mark - Table View Data Source Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.linkResults) {
        NSDictionary * sectionDict = [self.linkResults objectAtIndex:section];
        return [[sectionDict objectForKey:kLinksKeySectionLinks] count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseID = @"links_cell";
    UITableViewCell *cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseID] autorelease];
    }
    
    NSDictionary *section = [self.linkResults objectAtIndex:indexPath.section];
    NSArray *links = [section objectForKey:kLinksKeySectionLinks];
    NSDictionary *currentLink = [links objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [currentLink objectForKey:kLinksKeyLinkTitle];
    cell.detailTextLabel.text = [currentLink objectForKey:kLinksKeyLinkUrl];
    
    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
    
    cell.textLabel.numberOfLines = 0;
    [cell applyStandardFonts];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.linkResults) {
        return [self.linkResults count];
    }
    return 0;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.linkResults) {
        NSString *headerTitle = [[self.linkResults objectAtIndex:section] objectForKey:kLinksKeySectionTitle];
        return [UITableView groupedSectionHeaderWithTitle:headerTitle];
    }
    return nil;
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return GROUPED_SECTION_HEADER_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *section = [self.linkResults objectAtIndex:indexPath.section];
    NSArray *links = [section objectForKey:kLinksKeySectionLinks];
    NSDictionary *currentLink = [links objectAtIndex:indexPath.row];
    
    NSString *title = [currentLink objectForKey:kLinksKeyLinkTitle];
    NSString *url = [currentLink objectForKey:kLinksKeyLinkUrl];

    CGFloat padding = 10.0f;
    CGFloat linkTitleWidth = CGRectGetWidth(tableView.bounds) - (3 * padding + 39); // padding on each side due to being a grouped tableview + padding on left + 39px of accessory view on right
    CGSize titleSize = [title sizeWithFont:[UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE] constrainedToSize:CGSizeMake(linkTitleWidth, 2000) lineBreakMode:UILineBreakModeWordWrap];
    
    CGSize urlSize = [url sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE] constrainedToSize:CGSizeMake(linkTitleWidth, 2000) lineBreakMode:UILineBreakModeTailTruncation];

    return MAX(titleSize.height + urlSize.height + 2 * padding, tableView.rowHeight);
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *section = [self.linkResults objectAtIndex:indexPath.section];
    NSArray *links = [section objectForKey:kLinksKeySectionLinks];
    NSDictionary *currentLink = [links objectAtIndex:indexPath.row];
    
    NSString *urlString = [currentLink objectForKey:kLinksKeyLinkUrl];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: urlString]];
}

#pragma mark - Link Caching

- (NSString *) findOrCreateDirectory:(NSSearchPathDirectory) searchPathDirectory inDomain:(NSSearchPathDomainMask) domainMask appendComponent:(NSString *) appendComponenent error:(NSError **) errorOut
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(searchPathDirectory, domainMask, YES);
    if ([paths count] == 0) {
        NSDictionary *errorDict = @{ NSLocalizedDescriptionKey : @"No file or directory at requested location" };
        if (errorOut != NULL) {
            *errorOut = [NSError errorWithDomain:NSCocoaErrorDomain code:405 userInfo:errorDict];
        }
        return nil;
    }
    
    NSString *resolvedPath = [paths objectAtIndex:0];
    
    if (appendComponenent) {
        resolvedPath = [resolvedPath stringByAppendingPathComponent:appendComponenent];
    }
    
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager
                        createDirectoryAtPath:resolvedPath
                        withIntermediateDirectories:YES
                        attributes:nil
                        error:&error];
    
    if (!success) {
        if (errorOut) {
            *errorOut = error;
        }
        return nil;
    }
    
    if (errorOut) {
        *errorOut = nil;
    }
    
    return resolvedPath;
}

- (NSString *) applicationCachesDirectory
{
    NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    NSError *error;
    NSString *result = [self findOrCreateDirectory:NSCachesDirectory
                                          inDomain:NSUserDomainMask
                                   appendComponent:executableName
                                             error:&error];
    if (error) {
        ELog(@"Unable to find or create application caches directory:\n%@", error);
    }
    return result;
}

- (NSString *)linkCachePath {
    return [[self applicationCachesDirectory] stringByAppendingPathComponent:kLinksCacheFileName];
}

- (void) saveLinksToCache:(NSArray *) linksArray
{
    NSString *linksPlistPath = [self linkCachePath];
    [linksArray writeToFile:linksPlistPath atomically:YES];
}

- (NSArray *) cachedLinks
{
    NSArray *linksArray = [NSArray arrayWithContentsOfFile:[self linkCachePath]];
    return linksArray;
}


@end
