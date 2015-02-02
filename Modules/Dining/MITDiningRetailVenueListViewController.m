#import "MITDiningRetailVenueListViewController.h"
#import "MITDiningRetailVenue.h"
#import "MITDiningRetailVenueDetailViewController.h"
#import "MITDiningRetailVenueDataManager.h"
#import "MITDiningVenueCell.h"

static NSString *const kMITDiningVenueCell = @"MITDiningVenueCell";

@interface MITDiningRetailVenueListViewController () <MITDiningRetailVenueDetailViewControllerDelegate, MITDiningRefreshableViewController, MITDiningRetailVenueDataManagerDelegate>

@property (nonatomic) BOOL shouldUpdateTableData;

@end

@implementation MITDiningRetailVenueListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dataManager = [[MITDiningRetailVenueDataManager alloc] initWithRetailVenues:self.retailVenues];
    self.dataManager.delegate = self;
    
    [self setupTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.shouldUpdateTableData)
    {
        [self.dataManager updateSectionsAndVenueArrays];
        [self.tableView reloadData];
        self.shouldUpdateTableData = NO;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    return [self.dataManager numberOfSections];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.dataManager titleForSection:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataManager numberOfRowsInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITDiningRetailVenue *venue = [self.dataManager venueForIndexPath:indexPath];
    return  [MITDiningVenueCell heightForRetailVenue:venue
                                    withNumberPrefix:[self.dataManager absoluteIndexStringForVenue:venue]
                                      tableViewWidth:self.view.frame.size.width];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITDiningVenueCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITDiningVenueCell forIndexPath:indexPath];
   
    MITDiningRetailVenue *venue = [self.dataManager venueForIndexPath:indexPath];

    if ([venue.favorite boolValue] && indexPath.section == 0) { // Cell is in favorites section
        [cell setVenue:venue withNumberPrefix:nil];
    }
    else {
        [cell setVenue:venue withNumberPrefix:[self.dataManager absoluteIndexStringForVenue:venue]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    MITDiningRetailVenue *venue = [self.dataManager venueForIndexPath:indexPath];
    
    if ([self.delegate respondsToSelector:@selector(retailVenueListViewController:didSelectVenue:)]) {
        [self.delegate retailVenueListViewController:self didSelectVenue:venue];
    } else {
        MITDiningRetailVenueDetailViewController *detailVC = [[MITDiningRetailVenueDetailViewController alloc] initWithNibName:nil bundle:nil];
        detailVC.retailVenue = venue;
        detailVC.delegate = self;
        
        [self.navigationController pushViewController:detailVC animated:YES];
    }
}

#pragma mark - Setters

- (void)setRetailVenues:(NSArray *)retailVenues
{
    _retailVenues = retailVenues;
    self.dataManager.retailVenues = retailVenues;
    [self.tableView reloadData];
}

#pragma mark - Dining Retail Venue Detail Delegate

- (void)retailDetailViewController:(MITDiningRetailVenueDetailViewController *)viewController didUpdateFavoriteStatusForVenue:(MITDiningRetailVenue *)venue
{
    self.shouldUpdateTableData = YES;
}

- (void)dataManagerDidUpdateSectionTitles:(MITDiningRetailVenueDataManager *)dataManager
{
    [self.tableView reloadData];
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
    [self.tableView reloadData];
}

@end
