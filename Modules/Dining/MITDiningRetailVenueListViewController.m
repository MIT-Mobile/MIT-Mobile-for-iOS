#import "MITDiningRetailVenueListViewController.h"
#import "MITCoreData.h"
#import "MITAdditions.h"

#import "MITDiningRetailVenue.h"
#import "MITDiningRetailVenueDetailViewController.h"
#import "MITDiningRetailVenueDataManager.h"
#import "MITDiningVenueCell.h"


static NSString *const kMITDiningVenueCell = @"MITDiningVenueCell";

@interface MITDiningRetailVenueListViewController ()

@property (nonatomic, strong) MITDiningRetailVenueDataManager *dataManager;

@end

@implementation MITDiningRetailVenueListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dataManager = [[MITDiningRetailVenueDataManager alloc] initWithRetailVenues:self.retailVenues];
    
    [self setupTableView];
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

    [cell setVenue:venue withNumberPrefix:[self.dataManager absoluteIndexStringForVenue:venue]];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Setters

- (void)setRetailVenues:(NSArray *)retailVenues
{
    _retailVenues = retailVenues;
    self.dataManager.retailVenues = retailVenues;
    [self.tableView reloadData];
}

@end
