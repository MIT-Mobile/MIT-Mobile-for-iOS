
#import "LinksViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"
#import "MIT_MobileAppDelegate.h"

@interface LinksViewController ()
@property (copy) NSArray *linkResults;

@property (nonatomic,weak) MITLoadingActivityView *loadingView;
@property (nonatomic,weak) UILabel *errorLabel;
@property (nonatomic,weak) MITTouchstoneRequestOperation *linksRequestOperation;
@end

static NSString* const MITLinksDataCacheName = @"links_cache.plist";
static NSString* const MITLinksDataSectionTitleKey = @"title";
static NSString* const MITLinksDataSectionKey = @"links";
static NSString* const MITLinksDataURLKey = @"link";
static NSString* const MITLinksDataTitleKey = @"name";

@implementation LinksViewController
- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.title = @"Links";
}

- (BOOL)wantsFullScreenLayout
{
    // iOS 7 compatibility
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.tableView.backgroundView = nil;
    self.linkResults = [self cachedLinks];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.errorLabel removeFromSuperview];
    
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

#pragma mark - Loading View

- (void) showLoadingView {
    if (!self.loadingView) {
        self.tableView.userInteractionEnabled = NO;
        CGRect loadingFrame = self.tableView.bounds;
        MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:loadingFrame];
        loadingView.usesBackgroundImage = NO;
        self.loadingView = loadingView;
        [self.view addSubview:self.loadingView];
    }
}

- (void) removeLoadingView {
    self.tableView.userInteractionEnabled = YES;
    [self.loadingView removeFromSuperview];
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
    NSURLRequest *request = [NSURLRequest requestForModule:@"links" command:nil parameters:nil];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

    __weak LinksViewController *weakSelf = self;
    requestOperation.completeBlock = ^(MITTouchstoneRequestOperation *operation, NSArray *jsonResult, NSString *contentType, NSError *error) {
        LinksViewController *blockSelf = weakSelf;

        if (!blockSelf) {
            return;
        } else if (blockSelf.linksRequestOperation != operation) {
            return;
        } else if (error || ![jsonResult isKindOfClass:[NSArray class]]) {
            // If there was an error or if the jsonResult is not an array as expected, ignore this call and rely on the cache.
            // If there is no cache, report the error.
            if ([blockSelf.linkResults count] == 0) {
                [self displayLoadingError];
            }
        } else {
            [self updateLinksIfNeeded:jsonResult];
        }
    };

    [self.linksRequestOperation cancel];
    self.linksRequestOperation = requestOperation;
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

- (void)displayLoadingError {
    [self removeLoadingView];
    CGFloat horizontalPadding = 20.0;
    CGRect frame = self.tableView.bounds;
    frame.origin.x = horizontalPadding;
    frame.size.width -= 2 * horizontalPadding;
    UILabel *errorLabel = [[UILabel alloc] initWithFrame:frame];
    errorLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    errorLabel.backgroundColor = [UIColor clearColor];
    errorLabel.text = @"There was a problem loading the links. Please try again later.";
    errorLabel.textAlignment = NSTextAlignmentCenter;
    errorLabel.shadowColor = [UIColor whiteColor];
    errorLabel.shadowOffset = CGSizeMake(0, 1);
    errorLabel.numberOfLines = 0;
    errorLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    self.errorLabel = errorLabel;
    [self.tableView addSubview:errorLabel];
    
    self.tableView.userInteractionEnabled = NO;
}

#pragma mark - Table View Data Source Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.linkResults) {
        NSDictionary * sectionDict = self.linkResults[section];
        return [sectionDict[MITLinksDataSectionKey] count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseID = @"links_cell";
    UITableViewCell *cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseID];
    }
    
    NSDictionary *section = [self.linkResults objectAtIndex:indexPath.section];
    NSArray *links = section[MITLinksDataSectionKey];
    NSDictionary *currentLink = links[indexPath.row];
    
    cell.textLabel.text = currentLink[MITLinksDataTitleKey];
    cell.detailTextLabel.text = currentLink[MITLinksDataURLKey];
    cell.detailTextLabel.textColor = [UIColor darkGrayColor];
    
    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
    
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.numberOfLines = 0;
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.linkResults) {
        return [self.linkResults count];
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.linkResults) {
        return self.linkResults[section][MITLinksDataSectionTitleKey];
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // There's probably a better way to do this —
    // one that doesn't require hardcoding expected padding.
    
    // UITableViewCellStyleSubtitle layout differs between iOS 6 and 7
    static UIEdgeInsets labelInsets;
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        labelInsets = UIEdgeInsetsMake(11., 15., 11., 34. + 2.);
    } else {
        labelInsets = UIEdgeInsetsMake(11., 10. + 10., 11., 10. + 39.);
    }
    
    NSDictionary *section = self.linkResults[indexPath.section];
    NSArray *links = section[MITLinksDataSectionKey];
    NSDictionary *currentLink = links[indexPath.row];
    
    NSString *title = currentLink[MITLinksDataTitleKey];
    NSString *url = currentLink[MITLinksDataURLKey];

    CGFloat linkTitleWidth = CGRectGetWidth(UIEdgeInsetsInsetRect(tableView.bounds, labelInsets));
    CGSize titleSize = [title sizeWithFont:[UIFont systemFontOfSize:[UIFont buttonFontSize]] constrainedToSize:CGSizeMake(linkTitleWidth, 2000) lineBreakMode:NSLineBreakByWordWrapping];
    
    CGSize urlSize = [url sizeWithFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]] constrainedToSize:CGSizeMake(linkTitleWidth, 2000) lineBreakMode:NSLineBreakByTruncatingTail];

    return MAX(titleSize.height + urlSize.height + labelInsets.top + labelInsets.bottom, tableView.rowHeight);
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *section = self.linkResults[indexPath.section];
    NSArray *links = section[MITLinksDataSectionKey];
    NSDictionary *currentLink = links[indexPath.row];
    
    NSURL *linkURL = [NSURL URLWithString:currentLink[MITLinksDataURLKey]];
    
    if ([[UIApplication sharedApplication] canOpenURL:linkURL]) {
        [[UIApplication sharedApplication] openURL:linkURL];
    }
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
    NSString *executableName = [[NSBundle mainBundle] infoDictionary][@"CFBundleExecutable"];
    NSError *error;
    NSString *result = [self findOrCreateDirectory:NSCachesDirectory
                                          inDomain:NSUserDomainMask
                                   appendComponent:executableName
                                             error:&error];
    if (error) {
        DDLogError(@"Unable to find or create application caches directory:\n%@", error);
    }
    return result;
}

- (NSString *)linkCachePath {
    return [[self applicationCachesDirectory] stringByAppendingPathComponent:MITLinksDataCacheName];
}

- (void) saveLinksToCache:(NSArray *) linksArray
{
    NSString *linksPlistPath = [self linkCachePath];
    [linksArray writeToFile:linksPlistPath atomically:YES];
}

- (NSArray *) cachedLinks
{
    return [[NSArray alloc] initWithContentsOfFile:[self linkCachePath]];
}


@end
