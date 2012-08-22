
#import "LinksViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"

@interface LinksViewController ()

@end

#define PADDING 10
#define LINK_TITLE_WIDTH 250

static NSString * kLinksCacheFileName = @"links_cache.plist";

static NSString * kLinksKeySectionTitle = @"title";
static NSString * kLinksKeySectionLinks = @"links";
static NSString * kLinksKeyLinkUrl      = @"link";
static NSString * kLinksKeyLinkTitle    = @"name";

@implementation LinksViewController

- (void) dealloc
{
    [table release];
    [_linkResults release];
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
    
    table = [[UITableView alloc]    initWithFrame:CGRectInset(self.view.bounds, 0, 0)
                                        style:UITableViewStyleGrouped];
    table.delegate = self;
    table.dataSource = self;
    [table setBackgroundColor:[UIColor clearColor]];
    [table applyStandardColors];
    
    [self.view addSubview:table];
    
    _linkResults = [[self loadLinksFromCache] copy];
    
    [self reloadTableView];
}

- (void) viewDidAppear:(BOOL)animated
{
    if (!_linkResults) {
        [self showLoadingViewWithDelay:0.0];
    }
    [self queryForLinks];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Loading View

- (void) showLoadingViewWithDelay:(float) delay {
    if (!_loadingView) {
        _loadingView = [[MITLoadingActivityView alloc] initWithFrame:CGRectInset(self.view.frame, 0, 0)];
        _loadingView.usesBackgroundImage = NO;
        _loadingView.alpha = 0.0;
        [self.view addSubview:_loadingView];
        
        [UIView animateWithDuration:0.3f delay:delay options:UIViewAnimationCurveEaseInOut animations:^(void){
            _loadingView.alpha = 1.0;
        }completion:^(BOOL finished){
        }];
    }
}

- (void) removeLoadingView {
    [UIView animateWithDuration:0.3f delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^(void){
        _loadingView.alpha = 0.0;
    }completion:^(BOOL finished){
        [_loadingView removeFromSuperview];
        _loadingView = nil;
    }];
    
}

#pragma mark - Misc Helpers

- (void) reloadTableView
{
    [table reloadData];
}

- (CGFloat)heightForLinkTitle:(NSString *)aTitle {
    CGSize titleSize = [aTitle sizeWithFont:[UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE] constrainedToSize:CGSizeMake(LINK_TITLE_WIDTH, 100)];
    return titleSize.height;
}

#pragma mark - Server/Cache Difference handling

- (void) replaceTableViewWithUpdatedLinks
{
    [self reloadTableView];
    [self showTableView];
    
    [self removeLoadingView];
    _loadingView = nil;
    
}

- (void) hideTableView
{
    [self showLoadingViewWithDelay:0.4];
    [UIView animateWithDuration:0.8f delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^(void){
        table.frame = CGRectMake(0, 0, CGRectGetWidth(table.bounds), 0);
        table.alpha = 0.0;
    }completion:^(BOOL finished){
        table.hidden = YES;
        [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(replaceTableViewWithUpdatedLinks) userInfo:nil repeats:NO];
    }];
}

- (void) showTableView
{
    table.hidden = NO;
    [UIView animateWithDuration:0.8f delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^(void){
        table.frame = CGRectMake(0, 0, CGRectGetWidth(table.bounds), CGRectGetHeight(self.view.bounds));
        table.alpha = 1.0;
    }completion:^(BOOL finished){
    
    }];
}

#pragma mark - Connection
- (void) queryForLinks
{
    MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"links"
                                                                            command:nil
                                                                         parameters:nil];
    
    operation.completeBlock = ^(MobileRequestOperation *operation, NSDictionary *codeInfo, NSError *error)
    {
        [self handleRequestResponse:codeInfo
                              error:error];
        [self saveLinksToCache:codeInfo];
    };

    [operation start];
}

- (void)cleanUpConnection {
	requestWasDispatched = NO;
}

- (void)handleRequestResponse:(NSDictionary *)result error:(NSError *) error
{
    if (error == nil) {
        [self cleanUpConnection];
        if (result && [result isKindOfClass:[NSArray class]]) {
            if (![(NSArray *)result isEqualToArray:_linkResults]) {     // remove ! to test case where cache is different from server response
                _linkResults = [result copy];
                [self hideTableView];
            }
        } else {
            _linkResults = nil;
        }
        
    }
}

#pragma mark - Table View Data Source Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_linkResults) {
        NSDictionary * sectionDict = [_linkResults objectAtIndex:section];
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
    
    NSDictionary *section = [_linkResults objectAtIndex:indexPath.section];
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
    if (_linkResults) {
        return [_linkResults count];
    }
    return 0;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (_linkResults) {
        NSString *headerTitle = [[_linkResults objectAtIndex:section] objectForKey:kLinksKeySectionTitle];
        return [UITableView groupedSectionHeaderWithTitle:headerTitle];
    }
    return nil;
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return GROUPED_SECTION_HEADER_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *section = [_linkResults objectAtIndex:indexPath.section];
    NSArray *links = [section objectForKey:kLinksKeySectionLinks];
    NSDictionary *currentLink = [links objectAtIndex:indexPath.row];
    
    NSString *title = [currentLink objectForKey:kLinksKeyLinkTitle];
    return MAX([self heightForLinkTitle:title] + 2 * PADDING, tableView.rowHeight);
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *section = [_linkResults objectAtIndex:indexPath.section];
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
        *errorOut = [NSError errorWithDomain:@"Link Cache" code:405 userInfo:errorDict];
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

- (void) saveLinksToCache:(NSDictionary *) linksDictionary
{
    NSString *linksPlistPath = [[self applicationCachesDirectory] stringByAppendingPathComponent:kLinksCacheFileName];
    [linksDictionary writeToFile:linksPlistPath atomically:YES];
}

- (NSArray *) loadLinksFromCache
{
    NSArray *loaded = [NSArray arrayWithContentsOfFile:[[self applicationCachesDirectory] stringByAppendingPathComponent:kLinksCacheFileName]];
    return loaded;
}


@end
