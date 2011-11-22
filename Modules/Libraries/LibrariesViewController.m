#import "MITUIConstants.h"
#import "LibrariesLocationsHoursViewController.h"
#import "LibrariesViewController.h"
#import "MITConstants.h"
#import "LibrariesAccountViewController.h"
#import "LibrariesAskUsTableViewController.h"
#import "LibrariesTellUsViewController.h"


// links expiration time 10 days
#define LinksExpirationTime 864000   

#define NUMBER_OF_SECTIONS 2
#define TOP_SECTION 0
#define EXTERNAL_URLS_SECTION 1

#define LINK_TITLE_WIDTH 250
#define LINK_TITLE_TAG 1
#define PADDING 10

@interface LibrariesViewController (Private)

- (void)loadLinksFromUserDefaults;
- (void)loadLinksFromServer;
- (void)showLinksLoadingFailure;

@end

@implementation LibrariesViewController
@synthesize tableView;
@synthesize searchBar;
@synthesize linksRequest;
@synthesize links;
@synthesize linksStatus;
@synthesize searchController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    self.linksRequest = nil;
    self.links = nil;
    self.tableView = nil;
    self.searchController.navigationController = nil;
    self.searchController = nil;
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
    self.searchBar.tintColor = SEARCH_BAR_TINT_COLOR;
    self.searchBar.delegate = self;
    self.searchDisplayController.delegate = self;
    self.title = @"Libraries";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView applyStandardColors];
    
    NSDate *linksUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:LibrariesLinksUpdatedKey];
    if (linksUpdated && (-[linksUpdated timeIntervalSinceNow] < LinksExpirationTime)) {
        [self loadLinksFromUserDefaults]; 
    } else {
        [self loadLinksFromServer];
    }
    
    self.linksRequest = [[[MITMobileWebAPI alloc] initWithModule:@"libraries" command:@"links" parameters:nil] autorelease];
    self.searchController = [[[WorldCatSearchController alloc] init] autorelease];
    self.searchController.navigationController = self.navigationController;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.searchBar.delegate = nil;
    self.searchDisplayController.delegate = nil;
    self.searchBar = nil;
    self.searchController = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (CGFloat)heightForLinkTitle:(NSString *)aTitle {
    CGSize titleSize = [aTitle sizeWithFont:[UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE] constrainedToSize:CGSizeMake(LINK_TITLE_WIDTH, 100)];
    return titleSize.height;
}

#pragma mark - dataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    if (aTableView != self.tableView) {
        // must be for search results
        return [self.searchController numberOfSectionsInTableView:aTableView];
    }
    return NUMBER_OF_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section) {
        case TOP_SECTION:
            return 4;
            
        case EXTERNAL_URLS_SECTION:
            if (self.linksStatus == LinksStatusLoaded) {
                return self.links.count;
            } else {
                return 1;
            }
            
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *title = nil;
    UIView *accessoryView = nil;
    switch (indexPath.section) {
        case TOP_SECTION:
            switch (indexPath.row) {
                case 0:
                    accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewSecure];
                    title = @"Your Account";
                    break;
                case 1:
                    title = @"Locations & Hours";
                    break;
                case 2:
                    title = @"Ask Us!";
                    break;
                case 3:
                    accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewSecure];
                    title = @"Tell Us!";
                    break;
                    
                default:
                    break;
            }
            break;
            
        case EXTERNAL_URLS_SECTION:
            if (self.linksStatus != LinksStatusLoaded) {
                UITableViewCell *loadingStatusCell = [aTableView dequeueReusableCellWithIdentifier:@"LinksStatus"];
                if (!loadingStatusCell) {
                    loadingStatusCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LinksStatus"] autorelease];
                    loadingStatusCell.selectionStyle = UITableViewCellSelectionStyleNone;
                }
                
                if (self.linksStatus == LinksStatusLoading) {
                    loadingStatusCell.textLabel.text = @"Loading...";
                } else if (self.linksStatus == LinksStatusFailed) {
                    loadingStatusCell.textLabel.text = @"Failed to load links";
                }
                return loadingStatusCell;
            } else {
                UITableViewCell *linkCell = [aTableView dequeueReusableCellWithIdentifier:@"LinkCell"];
                if (!linkCell) {
                    linkCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LinkCell"] autorelease];
                    linkCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
                    linkCell.textLabel.numberOfLines = 0;
                    [linkCell applyStandardFonts];
                }
                
                NSString *title = [(NSDictionary *)[self.links objectAtIndex:indexPath.row] objectForKey:@"title"];
                linkCell.textLabel.text = title;
                return linkCell;
            }
            break;
            
        default:
            break;
    }
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:@"Libraries"];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Libraries"] autorelease];
    }
    
    cell.textLabel.text = title;
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (indexPath.section == TOP_SECTION) {
        if (accessoryView) {
            cell.accessoryView = accessoryView;
        } else {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.section) {
        case TOP_SECTION:
            return aTableView.rowHeight;
            break;
            
        case EXTERNAL_URLS_SECTION:
            if (self.linksStatus != LinksStatusLoaded) {
                return aTableView.rowHeight;
            } else {
                NSString *title = [(NSDictionary *)[self.links objectAtIndex:indexPath.row] objectForKey:@"title"];
                return MAX([self heightForLinkTitle:title] + 2 * PADDING, aTableView.rowHeight);
            }
        default:
            break;
    }
    return 0;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIViewController *vc = nil;    
    
    switch (indexPath.section) {
        case TOP_SECTION:
            switch (indexPath.row) {
                case 0:
                    // Your Account
                    vc = [[[LibrariesAccountViewController alloc] init] autorelease];
                    break;
                case 1:
                    // Locations and Hours
                    vc = [[[LibrariesLocationsHoursViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
                    break;
                case 2:
                    // Ask Us
                    vc = [[[LibrariesAskUsTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
                    break;
                case 3:
                    // Tell Us
                    vc = [[[LibrariesTellUsViewController alloc] init] autorelease];
                    break;
                    
                default:
                    break;
            }
            [self.navigationController pushViewController:vc animated:YES];
            break;
            
        case EXTERNAL_URLS_SECTION:
            if (self.linksStatus == LinksStatusLoaded) {
                NSString *urlString = [(NSDictionary *)[self.links objectAtIndex:indexPath.row] objectForKey:@"url"];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
            }
            break;
            
        default:
            break;
    }
    
}


- (void)loadLinksFromUserDefaults {
    self.links = [[NSUserDefaults standardUserDefaults] objectForKey:LibrariesLinksKey];
    self.linksStatus = LinksStatusLoaded;
    [self.tableView reloadData];
}

- (void)loadLinksFromServer {
    self.linksRequest = [[[MITMobileWebAPI alloc] initWithModule:@"libraries" command:@"links" parameters:nil] autorelease];
    self.linksRequest.jsonDelegate = self;
    [self.linksRequest start];
    self.linksStatus = LinksStatusLoading;
}

- (void)showLinksLoadingFailure {
    [MITMobileWebAPI showErrorWithHeader:@"Libraries"];
    self.linksStatus = LinksStatusFailed;
    [self.tableView reloadData];
}

#pragma mark - MITMobileWeb delegate

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject {
    // quick sanity check
    NSArray *linksArray = JSONObject;
    for (NSDictionary *linkDict in linksArray) {
        if (![[linkDict objectForKey:@"title"] isKindOfClass:[NSString class]]) {
            [self showLinksLoadingFailure];
            return;
        }
        if (![[linkDict objectForKey:@"url"] isKindOfClass:[NSString class]]) {
            [self showLinksLoadingFailure];
            return;
        }
    }
    
    // sanity checked passed
    [[NSUserDefaults standardUserDefaults] setObject:JSONObject forKey:LibrariesLinksKey];
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:LibrariesLinksUpdatedKey];
    self.linksStatus = LinksStatusLoaded;
    self.links = JSONObject;
    [self.tableView reloadData];
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
    return NO;
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
    // look for old cached version of links
    if ([[NSUserDefaults standardUserDefaults] objectForKey:LibrariesLinksKey]) {
        self.linksStatus = LinksStatusLoaded;
        self.links = [[NSUserDefaults standardUserDefaults] objectForKey:LibrariesLinksKey];
        [self.tableView reloadData];
    } else {
        [self showLinksLoadingFailure];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar {
    [self.searchController doSearch:aSearchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchController clearSearch];
}

#pragma mark - UISearchDisplayController delegate
- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)aTableView {
    [self.searchController clearSearch];
    aTableView.scrollsToTop = NO;
    self.tableView.scrollsToTop = YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)aTableView {
    aTableView.delegate = self.searchController;
    aTableView.dataSource = self.searchController;
    aTableView.scrollsToTop = YES;
    self.tableView.scrollsToTop = NO;
}

@end
