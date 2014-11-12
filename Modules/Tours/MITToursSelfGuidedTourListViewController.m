#import "MITToursSelfGuidedTourListViewController.h"
#import "MITToursTour.h"
#import "MITToursTourStopCell.h"
#import "MITToursTourDetailCell.h"
#import "MITToursStopCellModel.h"
#import "MITLocationManager.h"
#import "UIKit+MITAdditions.h"
#import "UIFont+MITTours.h"

typedef NS_ENUM(NSInteger, MITToursListSection) {
    MITToursListSectionDetails,
    MITToursListSectionMainLoop,
    MITToursListSectionSideTrips
};

static NSString *const kMITToursStopCell = @"MITToursTourStopCell";
static NSString *const kMITToursTourDetailCell = @"MITToursTourDetailCell";

@interface MITToursSelfGuidedTourListViewController ()

@property (nonatomic, strong) NSArray *mainLoopStops;
@property (nonatomic, strong) NSArray *sideTripsStops;

@property (nonatomic, strong) UIView *mainLoopSectionHeaderView;
@property (nonatomic, strong) UIView *sideTripsSectionHeaderView;

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

    UINib *cellNib = [UINib nibWithNibName:kMITToursTourDetailCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITToursTourDetailCell];
    
    cellNib = [UINib nibWithNibName:kMITToursStopCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITToursStopCell];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case MITToursListSectionDetails:
            return 1;
            break;
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == MITToursListSectionDetails) {
        return 0.0;
    }
    else {
        return 30.0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    switch (section) {
       case MITToursListSectionDetails:
            return nil;
            break;
        case MITToursListSectionMainLoop:
            return self.mainLoopSectionHeaderView;
            break;
        case MITToursListSectionSideTrips:
            return self.sideTripsSectionHeaderView;
        default:
            return nil;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == MITToursListSectionDetails) {
        return 92.0;
    }
    else {
        return [MITToursTourStopCell heightForContent:[self stopCellModelForIndexPath:indexPath] tableViewWidth:self.tableView.frame.size.width];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == MITToursListSectionDetails) {
        return [self.tableView dequeueReusableCellWithIdentifier:kMITToursTourDetailCell];
    }
    else {
        MITToursTourStopCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITToursStopCell];
        
        [cell setContent:[self stopCellModelForIndexPath:indexPath]];
        
        return cell;
    }
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

- (MITToursStop *)stopForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == MITToursListSectionMainLoop) {
        return self.mainLoopStops[indexPath.row];
    } else if (indexPath.section == MITToursListSectionSideTrips) {
        return self.sideTripsStops[indexPath.row];
    }
    return nil;
}

- (NSIndexPath *)indexPathForStop:(MITToursStop *)stop
{
    NSInteger index = [self.mainLoopStops indexOfObject:stop];
    if (index != NSNotFound) {
        return [NSIndexPath indexPathForRow:index inSection:MITToursListSectionMainLoop];
    }
    index = [self.sideTripsStops indexOfObject:stop];
    if (index != NSNotFound) {
        return [NSIndexPath indexPathForRow:index inSection:MITToursListSectionSideTrips];
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == MITToursListSectionDetails) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        if ([self.delegate respondsToSelector:@selector(selfGuidedTourListViewControllerDidPressInfoButton:)]) {
            [self.delegate selfGuidedTourListViewControllerDidPressInfoButton:self];
        }
    }
    else if ([self.delegate respondsToSelector:@selector(selfGuidedTourListViewController:didSelectStop:)]) {
        [self.delegate selfGuidedTourListViewController:self didSelectStop:[self stopForIndexPath:indexPath]];
    }
}

#pragma mark - Programmatic Stop Selection

- (void)selectStop:(MITToursStop *)stop
{
    NSIndexPath *indexPath = [self indexPathForStop:stop];
    if (indexPath) {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    }
}

- (void)deselectStop:(MITToursStop *)stop
{
    NSIndexPath *indexPath = [self indexPathForStop:stop];
    if (indexPath) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (UIView *)mainLoopSectionHeaderView
{
    if (!_mainLoopSectionHeaderView) {
        UIImageView *circleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tours/circle_red"]];
        circleView.frame = CGRectMake(8, 9, 12, 12);
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, self.tableView.frame.size.width - 40, 30)];
        label.font = [UIFont toursMapCalloutTitle];
        label.text = @"MAIN LOOP";
        _mainLoopSectionHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 30)];
        _mainLoopSectionHeaderView.backgroundColor = [UIColor mit_backgroundColor];
        [_mainLoopSectionHeaderView addSubview:circleView];
        [_mainLoopSectionHeaderView addSubview:label];
    }
    return _mainLoopSectionHeaderView;
}

- (UIView *)sideTripsSectionHeaderView
{
    if (!_sideTripsSectionHeaderView) {
        UIImageView *circleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tours/circle_blue"]];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, self.tableView.frame.size.width - 40, 30)];
        circleView.frame = CGRectMake(8, 9, 12, 12);
        label.font = [UIFont toursMapCalloutTitle];
        label.text = @"SIDE TRIPS";
        _sideTripsSectionHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 30)];
        _sideTripsSectionHeaderView.backgroundColor = [UIColor mit_backgroundColor];
        [_sideTripsSectionHeaderView addSubview:circleView];
        [_sideTripsSectionHeaderView addSubview:label];

    }
    return _sideTripsSectionHeaderView;
}

@end
