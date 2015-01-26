#import "MITDiningHouseVenueDetailViewController.h"
#import "MITDiningHouseVenueListViewController.h"
#import "MITDiningVenueCell.h"
#import "MITAdditions.h"
#import "MITDiningDining.h"
#import "MITDiningVenues.h"
#import "MITDiningLinks.h"
#import "MITSingleWebViewCellTableViewController.h"

typedef NS_ENUM(NSInteger, kMITVenueListSection) {
    kMITVenueListSectionAnnouncements = 0,
    kMITVenueListSectionVenues,
    kMITVenueListSectionLinks
};

static NSString *const kMITDiningAnnouncementsCell = @"kMITDiningAnnouncementsCell";
static NSString *const kMITDiningVenueCell = @"MITDiningVenueCell";
static NSString *const kMITDiningLinksCell = @"kMITDiningLinksCell";

@interface MITDiningHouseVenueListViewController ()

@property (nonatomic, strong) NSArray *houseVenues;
@property (nonatomic, strong) NSArray *diningLinks;

@end

@implementation MITDiningHouseVenueListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    [self setupTableView];
}

#pragma mark - Table view data source/delegate

- (void)setupTableView
{
    UINib *cellNib = [UINib nibWithNibName:kMITDiningVenueCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITDiningVenueCell];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlValueChanged) forControlEvents:UIControlEventValueChanged];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    
    switch (section) {
        case kMITVenueListSectionAnnouncements:
            return self.diningData.announcementsHTML ? @"ANNOUNCEMENTS" : nil;
            break;
        case kMITVenueListSectionVenues:
            return @"VENUES";
            break;
        case kMITVenueListSectionLinks:
            return @"RESOURCES";
            break;
        default:
            return @"";
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kMITVenueListSectionAnnouncements:
            return self.diningData.announcementsHTML ? 1 : 0;
            break;
        case kMITVenueListSectionVenues:
            return self.houseVenues.count;
            break;
        case kMITVenueListSectionLinks:
            return self.diningLinks.count;
            break;
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight = 44.0;
    if (indexPath.section == 1) {
        MITDiningHouseVenue *venue = self.houseVenues[indexPath.row];
        cellHeight = [MITDiningVenueCell heightForHouseVenue:venue tableViewWidth:self.view.frame.size.width];
    }
    return cellHeight;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kMITVenueListSectionAnnouncements:
            return [self announcementCell];
            break;
        case kMITVenueListSectionVenues:
            return [self houseVenueCellForIndexPath:indexPath];
            break;
        case kMITVenueListSectionLinks:
            return [self linksCellForIndexPath:indexPath];
            break;
        default:
            return nil;
            break;
    }
}

- (UITableViewCell *)houseVenueCellForIndexPath:(NSIndexPath *)indexPath
{
    MITDiningVenueCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITDiningVenueCell forIndexPath:indexPath];
    
    [cell setVenue:self.houseVenues[indexPath.row] withNumberPrefix:nil];
        
    return cell;
}

- (UITableViewCell *)announcementCell
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITDiningAnnouncementsCell];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITDiningAnnouncementsCell];
        cell.backgroundColor = [UIColor colorWithRed:255/255.0 green:253/255.0 blue:205/255.0 alpha:1];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [UIFont systemFontOfSize:17.0];
    }
    
    cell.textLabel.text = [[self.diningData.announcementsHTML stringByStrippingTags] stringByDecodingXMLEntities];
    
    return cell;
}

- (UITableViewCell *)linksCellForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITDiningLinksCell];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITDiningLinksCell];
        cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
    }
    
    MITDiningLinks *link = self.diningLinks[indexPath.row];
    cell.textLabel.text = link.name;
    cell.textLabel.font = [UIFont systemFontOfSize:17.0];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.section) {
        case kMITVenueListSectionAnnouncements:
        {
            MITSingleWebViewCellTableViewController *vc = [[MITSingleWebViewCellTableViewController alloc] init];
            vc.title = @"Announcements";
            vc.webViewInsets = UIEdgeInsetsMake(10, 10, 10, 10);
            vc.htmlContent = self.diningData.announcementsHTML;
            
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case kMITVenueListSectionVenues:
        {
            MITDiningHouseVenueDetailViewController *detailVC = [[MITDiningHouseVenueDetailViewController alloc] init];
            detailVC.houseVenue = self.houseVenues[indexPath.row];
            
            [self.navigationController pushViewController:detailVC animated:YES];
        }
            break;
        case kMITVenueListSectionLinks:
        {
            MITDiningLinks *link = self.diningLinks[indexPath.row];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link.url]];
        }
            break;
        default:
            break;
    }
}

#pragma mark - Refresh Control

- (void)refreshControlValueChanged
{
    if (self.refreshControl.refreshing && [self.refreshDelegate respondsToSelector:@selector(viewControllerRequestsDataUpdate:)]) {
        [self.refreshDelegate viewControllerRequestsDataUpdate:self];
    }
}

- (void)refreshRequestComplete
{
    [self.refreshControl endRefreshing];
}

#pragma mark - Setters

- (void)setDiningData:(MITDiningDining *)diningData
{
    _diningData = diningData;
    self.houseVenues = [[diningData.venues.house array] copy];
    self.diningLinks = [diningData.links array];

    [self.tableView reloadData];
}

@end
