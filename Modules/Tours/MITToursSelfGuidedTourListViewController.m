#import "MITToursSelfGuidedTourListViewController.h"
#import "MITToursTour.h"
#import "MITToursTourStopCell.h"
#import "MITToursStopCellModel.h"
#import "MITLocationManager.h"

typedef NS_ENUM(NSInteger, MITToursListSection) {
    MITToursListSectionMainLoop,
    MITToursListSectionSideTrips
};

static NSString *const kMITToursStopCell = @"MITToursTourStopCell";

@interface MITToursSelfGuidedTourListViewController ()

@property (nonatomic, strong) NSArray *mainLoopStops;
@property (nonatomic, strong) NSArray *sideTripsStops;

@end

@implementation MITToursSelfGuidedTourListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)setupTableView
{
    // Keep a local copy, since these are calculated properties
    self.mainLoopStops = self.tour.mainLoopStops;
    self.sideTripsStops = self.tour.sideTripsStops;
    
    UINib *cellNib = [UINib nibWithNibName:kMITToursStopCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITToursStopCell];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case MITToursListSectionMainLoop:
            return self.mainLoopStops.count;
            break;
        case MITToursListSectionSideTrips:
            return self.sideTripsStops.count;
        default:
            return 0;
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case MITToursListSectionMainLoop:
            return @"Main Loop";
            break;
        case MITToursListSectionSideTrips:
            return @"Side Trip";
        default:
            return nil;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [MITToursTourStopCell heightForContent:[self stopCellModelForIndexPath:indexPath] tableViewWidth:self.tableView.frame.size.width];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITToursTourStopCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITToursStopCell];
    
    [cell setContent:[self stopCellModelForIndexPath:indexPath]];
    
    return cell;
}

- (MITToursStopCellModel *)stopCellModelForIndexPath:(NSIndexPath *)indexPath
{
    MITToursStop *stop;
    NSInteger stopIndex;
    
    if (indexPath.section == MITToursListSectionMainLoop) {
        stop = self.mainLoopStops[indexPath.row];
        stopIndex = indexPath.row;
    }
    else {
        stop = self.sideTripsStops[indexPath.row];
        stopIndex = self.mainLoopStops.count + indexPath.row;
    }
    
    return [[MITToursStopCellModel alloc] initWithStop:stop stopIndex:stopIndex];
}

@end
