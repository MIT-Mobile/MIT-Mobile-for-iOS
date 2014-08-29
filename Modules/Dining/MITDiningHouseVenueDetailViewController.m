#import "MITDiningHouseVenueDetailViewController.h"
#import "MITDiningHouseVenueInfoViewController.h"
#import "MITDiningHouseMealSelectionView.h"
#import "MITDiningHouseVenueInfoCell.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningHouseDay.h"
#import "MITDiningMeal.h"
#import "Foundation+MITAdditions.h"

typedef NS_ENUM(NSInteger, kMITVenueDetailSection) {
    kMITVenueDetailSectionInfo,
    kMITVenueDetailSectionMenu
};

static NSString *const kMITDiningHouseVenueInfoCell = @"MITDiningHouseVenueInfoCell";

@interface MITDiningHouseVenueDetailViewController () <MITDiningHouseVenueInfoCellDelegate>

@property (nonatomic, strong) MITDiningHouseDay *currentlySelectedDay;
@property (nonatomic, strong) MITDiningMeal *currentlyDisplayedMeal;

@property (nonatomic, strong) NSDate *currentlyDisplayedDate;

@property (nonatomic, strong) MITDiningHouseMealSelectionView *mealSelectionView;

@end

@implementation MITDiningHouseVenueDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.houseVenue.name;
    
    self.currentlyDisplayedDate = [NSDate date];
    
    self.currentlySelectedDay = [self.houseVenue houseDayForDate:self.currentlyDisplayedDate];
    self.currentlyDisplayedMeal = [self.currentlySelectedDay bestMealForDate:self.currentlyDisplayedDate];
    
    [self setupTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (void)setupTableView
{
    UINib *cellNib = [UINib nibWithNibName:kMITDiningHouseVenueInfoCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITDiningHouseVenueInfoCell];
    
    self.mealSelectionView = [[[NSBundle mainBundle] loadNibNamed:@"MITDiningHouseMealSelectionView" owner:nil options:nil] firstObject];
    [self.mealSelectionView.nextMealButton addTarget:self action:@selector(nextMealPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.mealSelectionView.previousMealButton addTarget:self action:@selector(previousMealPressed:) forControlEvents:UIControlEventTouchUpInside];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == kMITVenueDetailSectionMenu ? 64.0 : 0.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kMITVenueDetailSectionInfo:
            return [MITDiningHouseVenueInfoCell heightForHouseVenue:self.houseVenue tableViewWidth:self.tableView.frame.size.width];
            break;
        case kMITVenueDetailSectionMenu:
            return 44.0;
            break;
        default:
            return 0;
            break;
    }

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kMITVenueDetailSectionInfo:
            return 1;
            break;
        case kMITVenueDetailSectionMenu:
            return self.currentlyDisplayedMeal.items.count;
            break;
        default:
            return 0;
            break;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case kMITVenueDetailSectionInfo:
            return nil;
            break;
        case kMITVenueDetailSectionMenu:
            [self updateMealSelectionView];
            return self.mealSelectionView;
            break;
        default:
            return nil;
            break;

    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kMITVenueDetailSectionInfo:
            return [self venueInfoCell];
            break;
            
        default:
            break;
    }
    return [[UITableViewCell alloc] init];
    
}

- (UITableViewCell *)venueInfoCell
{
    MITDiningHouseVenueInfoCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITDiningHouseVenueInfoCell];
    [cell setHouseVenue:self.houseVenue];
    cell.delegate = self;
    return cell;
}

#pragma mark - Cell Delegate
- (void)infoCellDidPressInfoButton:(MITDiningHouseVenueInfoCell *)infoCell
{
    MITDiningHouseVenueInfoViewController *infoVC = [[MITDiningHouseVenueInfoViewController alloc] init];
    infoVC.houseVenue = self.houseVenue;
    
    [self.navigationController pushViewController:infoVC animated:YES];
}


#pragma mark - Meal Selection View

- (void)updateMealSelectionView
{
    self.mealSelectionView.meal = self.currentlyDisplayedMeal;
}

- (void)nextMealPressed:(id)sender
{

}

- (void)previousMealPressed:(id)sender
{


}



@end
