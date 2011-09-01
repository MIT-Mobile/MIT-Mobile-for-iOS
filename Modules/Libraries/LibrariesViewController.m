#import "MITUIConstants.h"
#import "LibrariesLocationsHoursViewController.h"
#import "LibrariesViewController.h"
#import "MITConstants.h"


// links expiration time 10 days
#define LinksExpirationTime 864000   

#define NUMBER_OF_SECTIONS 2
#define TOP_SECTION 0
#define EXTERNAL_URLS_SECTION 1

@interface LibrariesViewController (Private)

- (void)loadLinksFromUserDefaults;
- (void)loadLinksFromServer;
- (void)showLinksLoadingFailure;

@end

@implementation LibrariesViewController
@synthesize searchBar;
@synthesize linksRequest;
@synthesize links;
@synthesize linksStatus;

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
    self.title = @"Libraries";
    [self.tableView applyStandardColors];
    
    NSDate *linksUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:LibrariesLinksUpdatedKey];
    if (linksUpdated && (-[linksUpdated timeIntervalSinceNow] < LinksExpirationTime)) {
        [self loadLinksFromUserDefaults]; 
    } else {
        [self loadLinksFromServer];
    }
    
    self.linksRequest = [[[MITMobileWebAPI alloc] initWithModule:@"libraries" command:@"links" parameters:nil] autorelease];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - dataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUMBER_OF_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *title;
    switch (indexPath.section) {
        case TOP_SECTION:
            switch (indexPath.row) {
                case 0:
                    title = @"Your Account";
                    break;
                case 1:
                    title = @"Locations & Hours";
                    break;
                case 2:
                    title = @"Ask Us!";
                    break;
                case 3:
                    title = @"Tell Us!";
                    break;
                    
                default:
                    break;
            }
            break;
            
        case EXTERNAL_URLS_SECTION:
            if (self.linksStatus != LinksStatusLoaded) {
                UITableViewCell *loadingStatusCell = [tableView dequeueReusableCellWithIdentifier:@"LinksStatus"];
                if (!loadingStatusCell) {
                    loadingStatusCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LinksStatus"] autorelease];
                    loadingStatusCell.selectionStyle = UITableViewCellEditingStyleNone;
                }
                
                if (self.linksStatus == LinksStatusLoading) {
                    loadingStatusCell.textLabel.text = @"Loading...";
                } else if (self.linksStatus == LinksStatusFailed) {
                    loadingStatusCell.textLabel.text = @"Failed to load links";
                }
                return loadingStatusCell;
            } else {
                UITableViewCell *linkCell = [tableView dequeueReusableCellWithIdentifier:@"LinkCell"];
                if (!linkCell) {
                    linkCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LinkCell"] autorelease];
                }
                
                linkCell.textLabel.text = [(NSDictionary *)[self.links objectAtIndex:indexPath.row] objectForKey:@"title"];
                return linkCell;
            }
            break;
            
        default:
            break;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Libraries"];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Libraries"] autorelease];
    }
    
    cell.textLabel.text = title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIViewController *vc;
    NSString *urlString = nil;
    
    
    switch (indexPath.section) {
        case TOP_SECTION:
            switch (indexPath.row) {
                case 0:
                    // Your Account
                    break;
                case 1:
                    // Locations and Hours
                    vc = [[[LibrariesLocationsHoursViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
                    [self.navigationController pushViewController:vc animated:YES];
                    break;
                case 2:
                    // Ask Us
                    break;
                case 3:
                    // Tell Us
                    break;
                    
                default:
                    break;
            }
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

@end
