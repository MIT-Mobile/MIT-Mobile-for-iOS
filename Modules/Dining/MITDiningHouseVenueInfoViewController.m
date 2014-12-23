#import "MITDiningHouseVenueInfoViewController.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningLocation.h"
#import "UIKit+MITAdditions.h"
#import "MITMapModelController.h"
#import "MITDiningScheduleCell.h"
#import "MITDiningVenueInfoCell.h"
#import "Foundation+MITAdditions.h"

static NSString *const kMITDiningHouseVenueInfoCell = @"MITDiningVenueInfoCell";
static NSString *const kMITDiningScheduleCell = @"MITDiningScheduleCell";
static NSString *const kMITDiningPaymentCell = @"kMITDiningPaymentCell";
static NSString *const kMITDiningLocationCell = @"kMITDiningLocationCell";

typedef NS_ENUM(NSInteger, kMITVenueInfoSection) {
    kMITVenueInfoVenueHeaderAndPayment,
    kMITVenueInfoSectionSchedule,
    kMITVenueInfoSectionLocation
};

@interface MITDiningHouseVenueInfoViewController ()

@property (nonatomic, strong) NSArray *mealSummaries;

@end

@implementation MITDiningHouseVenueInfoViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.houseVenue.shortName;
    
    [self setupTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupTableView
{
    UINib *cellNib = [UINib nibWithNibName:kMITDiningScheduleCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITDiningScheduleCell];
    
    cellNib = [UINib nibWithNibName:kMITDiningHouseVenueInfoCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITDiningHouseVenueInfoCell];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)dismiss
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kMITVenueInfoVenueHeaderAndPayment:
            return 2;
            break;
        case kMITVenueInfoSectionSchedule:
            return self.mealSummaries.count;
            break;
        case kMITVenueInfoSectionLocation:
            return 1;
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kMITVenueInfoVenueHeaderAndPayment:
            if (indexPath.row == 0) {
                return [MITDiningVenueInfoCell heightForHouseVenue:self.houseVenue tableViewWidth:self.tableView.frame.size.width];
            }
            else {
                return 60;
            }
            break;
        case kMITVenueInfoSectionSchedule:
            return [MITDiningScheduleCell heightForMealSummary:self.mealSummaries[indexPath.row] tableViewWidth:self.tableView.frame.size.width];
            break;
        case kMITVenueInfoSectionLocation:
            return 60;
            break;
        default:
            return 60;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kMITVenueInfoVenueHeaderAndPayment:
            if (indexPath.row == 0) {
                return [self venueHeaderCell];
            }
            else {
                return [self paymentCell];
            }
            break;
        case kMITVenueInfoSectionSchedule:
            return [self scheduleCellForIndexPath:indexPath];
            break;
        case kMITVenueInfoSectionLocation:
            return [self locationCell];
            break;
        default:
            return nil;
            break;
    }
}

- (UITableViewCell *)venueHeaderCell
{
    MITDiningVenueInfoCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITDiningHouseVenueInfoCell];
    [cell setHouseVenue:self.houseVenue];
    cell.infoButton.hidden = YES;
    return cell;
}

- (UITableViewCell *)paymentCell
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITDiningPaymentCell];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kMITDiningPaymentCell];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.textColor = [UIColor mit_tintColor];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:17];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = @"payment";
        cell.detailTextLabel.text = [[self.houseVenue.payment allObjects] componentsJoinedByString:@", "];
    }
    return cell;
}

- (UITableViewCell *)scheduleCellForIndexPath:(NSIndexPath *)indexPath
{
    MITDiningScheduleCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITDiningScheduleCell forIndexPath:indexPath];
    [cell setMealSummary:self.mealSummaries[indexPath.row]];
    if (indexPath.row + 1 < self.mealSummaries.count) {
        // This hides the separator line
        cell.separatorInset = UIEdgeInsetsMake(0, self.tableView.frame.size.width, 0, 0);
    }
    return cell;
}

- (UITableViewCell *)locationCell
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITDiningLocationCell];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kMITDiningLocationCell];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.textColor = [UIColor mit_tintColor];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:17];
        cell.textLabel.text = @"location";
        cell.detailTextLabel.text = self.houseVenue.location.locationDescription;
        cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == kMITVenueInfoSectionLocation) {
        if (self.houseVenue.location.mitRoomNumber) {
             [MITMapModelController openMapWithRoomNumber:self.houseVenue.location.mitRoomNumber];
        }
        else {
            [MITMapModelController openMapWithSearchString:self.houseVenue.location.locationDescription];
        }
    }
}

#pragma mark Setters/Getters

- (void)setHouseVenue:(MITDiningHouseVenue *)houseVenue
{
    _houseVenue = houseVenue;
    self.mealSummaries = [houseVenue groupedMealTimeSummaries];
    [self.tableView reloadData];
}

@end
