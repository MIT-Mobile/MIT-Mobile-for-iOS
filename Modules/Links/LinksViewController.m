
#import "LinksViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"

@interface LinksViewController ()

@end


#define kLinksKeySectionTitle @"title"
#define kLinksKeySectionLinks @"links"
#define kLinksKeyLinkUrl @"link"
#define kLinksKeyLinkTitle @"name"

#define PADDING 10
#define LINK_TITLE_WIDTH 250

@implementation LinksViewController
@synthesize urlMappingOperation;

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
}

- (void) viewDidAppear:(BOOL)animated
{
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

- (void) showLoadingView {
    _loadingView = [[MITLoadingActivityView alloc] initWithFrame:CGRectInset(self.view.frame, 0, 0)];
    _loadingView.usesBackgroundImage = NO;
    [self.view addSubview:_loadingView];
}

- (void) queryForLinks
{
    MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"links"
                                                                            command:nil
                                                                         parameters:nil];
    
    operation.completeBlock = ^(MobileRequestOperation *operation, NSDictionary *codeInfo, NSError *error)
    {
        [self handleRequestResponse:codeInfo
                               error:error];
    };
    
    self.urlMappingOperation = operation;
    [operation start];
}

- (void) reloadTableView
{
    [table reloadData];
}

- (CGFloat)heightForLinkTitle:(NSString *)aTitle {
    CGSize titleSize = [aTitle sizeWithFont:[UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE] constrainedToSize:CGSizeMake(LINK_TITLE_WIDTH, 100)];
    return titleSize.height;
}

#pragma mark - JSONLoadedDelegate

- (void)cleanUpConnection {
	requestWasDispatched = NO;
	[_loadingView removeFromSuperview];
}

- (void)handleRequestResponse:(NSDictionary *)result error:(NSError *) error
{
    if (error == nil) {
        [self cleanUpConnection];
        NSLog(@"Results Log     ::  \n%@", result);
        if (result && [result isKindOfClass:[NSArray class]]) {
            _linkResults = [result copy];
            [self reloadTableView];
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

@end
