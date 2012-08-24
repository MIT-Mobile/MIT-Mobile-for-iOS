
#import "LinksViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"
#import "MIT_MobileAppDelegate.h"

@interface LinksViewController ()
//  properties
    @property (nonatomic, assign) BOOL requestWasDispatched;
    @property (nonatomic, retain) NSArray *linkResults;
    @property (nonatomic, retain) MITLoadingActivityView *loadingView;
//  private methods
//    - (void) reloadAndShowTableView;
@end

#define PADDING 10

static NSString * kLinksCacheFileName = @"links_cache.plist";

static NSString * kLinksKeySectionTitle = @"title";
static NSString * kLinksKeySectionLinks = @"links";
static NSString * kLinksKeyLinkUrl      = @"link";
static NSString * kLinksKeyLinkTitle    = @"name";

@implementation LinksViewController

@synthesize requestWasDispatched;
@synthesize linkResults = _linkResults;
@synthesize loadingView = _loadingView;

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
    
    self.tableView = [[[UITableView alloc]    initWithFrame:CGRectInset(self.view.bounds, 0, 0)
                                        style:UITableViewStyleGrouped] autorelease];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView applyStandardColors];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.linkResults = [self loadLinksFromCache];
    
    [self reloadTableView];
}

- (void) viewWillAppear:(BOOL)animated
{
    if (!self.linkResults) {
        [self showLoadingView];
    }
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
        CGRect loadingFrame = [MITAppDelegate() rootNavigationController].view.bounds;
        self.loadingView = [[[MITLoadingActivityView alloc] initWithFrame:loadingFrame] autorelease];
        self.loadingView.usesBackgroundImage = NO;
        self.loadingView.alpha = 1.0;
        [self.view addSubview:self.loadingView];
    }
}

- (void) removeLoadingView {
    [self.loadingView removeFromSuperview];
    self.loadingView = nil;
}

#pragma mark - Misc Helpers

- (void) reloadTableView
{
    [self.tableView reloadData];
}

- (CGFloat)heightForLinkTitle:(NSString *)aTitle {
    float link_title_width = CGRectGetWidth(self.tableView.bounds) - 70;        // 20 for padding, 50 for good measure
    CGSize titleSize = [aTitle sizeWithFont:[UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE] constrainedToSize:CGSizeMake(link_title_width, 100)];
    return titleSize.height;
}

#pragma mark - Server/Cache Difference handling

- (void) reloadAndShowTableView:(NSTimer *) timer
{
    self.linkResults = [timer userInfo];
    
    [self reloadTableView];
    
    [self removeLoadingView];
}

- (void) refreshTableView:(NSArray *) linksCache
{
    self.linkResults = @[];             // empty the table
    [self reloadTableView];             // reload the empty table  (necessary because using a UITableViewController)
    
    [self showLoadingView];
    [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(reloadAndShowTableView:) userInfo:linksCache repeats:NO];
}

#pragma mark - Connection
- (void) queryForLinks
{
    MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"links"
                                                                            command:nil
                                                                         parameters:nil];
    
    operation.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSError *error)
    {
        [self handleRequestResponse:jsonResult
                              error:error];
        
    };

    [operation start];
}

- (void)cleanUpConnection {
	requestWasDispatched = NO;
}

- (void)handleRequestResponse:(id)jsonResult error:(NSError *) error
{
    if (error == nil) {
        [self cleanUpConnection];
        if (jsonResult && [jsonResult isKindOfClass:[NSArray class]]) {
            NSArray *jsonArray = (NSArray *)jsonResult;
            if (![jsonArray isEqualToArray:self.linkResults]) {     // remove ! to test case where cache is different from server response
                [self refreshTableView:[jsonArray retain]];
                [self saveLinksToCache:jsonArray];
            }
        } else {
            self.linkResults = nil;
        }
        
    }
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
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseID] autorelease];
    }
    
    NSDictionary *section = [self.linkResults objectAtIndex:indexPath.section];
    NSArray *links = [section objectForKey:kLinksKeySectionLinks];
    NSDictionary *currentLink = [links objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [currentLink objectForKey:kLinksKeyLinkTitle];
    
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
    return MAX([self heightForLinkTitle:title] + 2 * PADDING, tableView.rowHeight);
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
    NSString *result = [self
                            findOrCreateDirectory:NSCachesDirectory
                            inDomain:NSUserDomainMask
                            appendComponent:executableName
                            error:&error];
    if (error) {
        NSLog(@"Unable to find or create application caches directory:\n%@", error);
    }
    return result;
}

- (void) saveLinksToCache:(NSArray *) linksArray
{
    NSString *linksPlistPath = [[self applicationCachesDirectory] stringByAppendingPathComponent:kLinksCacheFileName];
    [linksArray writeToFile:linksPlistPath atomically:YES];
}

- (NSArray *) loadLinksFromCache
{
    NSArray *loaded = [NSArray arrayWithContentsOfFile:[[self applicationCachesDirectory] stringByAppendingPathComponent:kLinksCacheFileName]];
    return loaded;
}


@end
