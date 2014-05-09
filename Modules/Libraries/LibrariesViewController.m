#import "LibrariesLocationsHoursViewController.h"
#import "LibrariesViewController.h"
#import "MITConstants.h"
#import "LibrariesAccountViewController.h"
#import "LibrariesAskUsTableViewController.h"
#import "LibrariesTellUsViewController.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "UIKit+MITAdditions.h"

// links expiration time 10 days
#define LinksExpirationTime 86400

#define NUMBER_OF_SECTIONS 2
#define TOP_SECTION 0
#define EXTERNAL_URLS_SECTION 1

#define LINK_TITLE_WIDTH 250
#define LINK_TITLE_TAG 1
#define PADDING 10

@interface LibrariesViewController ()
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (copy) NSArray *links;

- (void)loadLinksFromUserDefaults;
- (void)loadLinksFromServer;
- (void)showLinksLoadingFailure;
@end

@implementation LibrariesViewController
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
    self.searchController.navigationController = nil;
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.tableView.backgroundView = nil;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    } else {
        self.tableView.backgroundColor = [UIColor mit_backgroundColor];
        self.searchBar.tintColor = [UIColor MITTintColor];
    }
    self.searchBar.delegate = self;
    self.searchDisplayController.delegate = self;
    self.title = @"Libraries";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
//    [self.tableView applyStandardColors];
    
    NSDate *linksUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:LibrariesLinksUpdatedKey];
    if (linksUpdated && (-[linksUpdated timeIntervalSinceNow] < LinksExpirationTime)) {
        [self loadLinksFromUserDefaults]; 
    } else {
        [self loadLinksFromServer];
    }
    
    self.searchController = [[WorldCatSearchController alloc] init];
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

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (CGFloat)heightForLinkTitle:(NSString *)aTitle {
    CGSize titleSize = [aTitle sizeWithFont:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]] constrainedToSize:CGSizeMake(LINK_TITLE_WIDTH, 100)];
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
                    loadingStatusCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LinksStatus"];
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
                    linkCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LinkCell"];
                    linkCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
                    linkCell.textLabel.numberOfLines = 0;
                }
                
                linkCell.textLabel.text = self.links[indexPath.row][@"title"];
                return linkCell;
            }
            break;
            
        default:
            break;
    }
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:@"Libraries"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Libraries"];
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
                NSString *title = self.links[indexPath.row][@"title"];
                CGFloat titleHeight = [self heightForLinkTitle:title] + 2 * PADDING;
                return MAX(titleHeight, aTableView.rowHeight);
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
                    vc = [[LibrariesAccountViewController alloc] init];
                    break;
                case 1:
                    // Locations and Hours
                    vc = [[LibrariesLocationsHoursViewController alloc] initWithStyle:UITableViewStyleGrouped];
                    break;
                case 2:
                    // Ask Us
                    vc = [[LibrariesAskUsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
                    break;
                case 3:
                    // Tell Us
                    vc = [[LibrariesTellUsViewController alloc] init];
                    break;
                    
                default:
                    break;
            }
            [self.navigationController pushViewController:vc animated:YES];
            break;
            
        case EXTERNAL_URLS_SECTION:
            if (self.linksStatus == LinksStatusLoaded) {
                NSURL *url = [[NSURL alloc] initWithString:self.links[indexPath.row][@"url"]];
                
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
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
    NSURLRequest *request = [NSURLRequest requestForModule:@"libraries" command:@"links" parameters:nil];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    requestOperation.completeBlock = ^(MITTouchstoneRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (error) {
            // look for old cached version of links
            
            if ([[NSUserDefaults standardUserDefaults] objectForKey:LibrariesLinksKey]) {
                self.linksStatus = LinksStatusLoaded;
                self.links = [[NSUserDefaults standardUserDefaults] objectForKey:LibrariesLinksKey];
                [self.tableView reloadData];
            } else {
                [self showLinksLoadingFailure];
            }
        } else {
            // quick sanity check
            NSArray *linksArray = jsonResult;
            for (NSDictionary *linkDict in linksArray) {
                if (![linkDict[@"title"] isKindOfClass:[NSString class]]) {
                    [self showLinksLoadingFailure];
                    return;
                }
                if (![linkDict[@"url"] isKindOfClass:[NSString class]]) {
                    [self showLinksLoadingFailure];
                    return;
                }
            }
            
            // sanity checked passed
            [[NSUserDefaults standardUserDefaults] setObject:jsonResult forKey:LibrariesLinksKey];
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:LibrariesLinksUpdatedKey];
            self.linksStatus = LinksStatusLoaded;
            self.links = jsonResult;
            [self.tableView reloadData];
        }
    };
    
    [[NSOperationQueue mainQueue] addOperation:requestOperation];

    self.linksStatus = LinksStatusLoading;
}

- (void)showLinksLoadingFailure {
    [UIAlertView alertViewForError:nil withTitle:@"Libraries" alertViewDelegate:nil];
    self.linksStatus = LinksStatusFailed;
    [self.tableView reloadData];
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
