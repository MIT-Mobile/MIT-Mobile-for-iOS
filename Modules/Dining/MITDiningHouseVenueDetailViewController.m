#import "MITDiningHouseVenueDetailViewController.h"
#import "MITDiningHouseVenueInfoViewController.h"
#import "MITDiningHouseMealSelectionView.h"
#import "MITDiningHouseVenueInfoCell.h"
#import "Foundation+MITAdditions.h"
#import "MITDiningMenuItemCell.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningHouseDay.h"
#import "MITDiningMeal.h"

typedef NS_ENUM(NSInteger, kMITVenueDetailSection) {
    kMITVenueDetailSectionInfo,
    kMITVenueDetailSectionMenu
};

static NSString *const kMITDiningHouseVenueInfoCell = @"MITDiningHouseVenueInfoCell";
static NSString *const kMITDiningMenuItemCell = @"MITDiningMenuItemCell";

@interface MITDiningHouseVenueDetailViewController () <MITDiningHouseVenueInfoCellDelegate>

@property (nonatomic, strong) MITDiningHouseDay *currentlyDisplayedDay;
@property (nonatomic, strong) MITDiningMeal *currentlyDisplayedMeal;

@property (nonatomic, strong) NSArray *sortedMeals;

@property (nonatomic, strong) NSDate *currentlyDisplayedDate;

@property (nonatomic, strong) MITDiningHouseMealSelectionView *mealSelectionView;

@end

@implementation MITDiningHouseVenueDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.houseVenue.name;
    
    self.currentlyDisplayedDate = [NSDate date];
    
    self.currentlyDisplayedDay = [self.houseVenue houseDayForDate:self.currentlyDisplayedDate];
    self.currentlyDisplayedMeal = [self.currentlyDisplayedDay bestMealForDate:self.currentlyDisplayedDate];
    
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
    
    cellNib = [UINib nibWithNibName:kMITDiningMenuItemCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITDiningMenuItemCell];
    
    self.mealSelectionView = [[[NSBundle mainBundle] loadNibNamed:@"MITDiningHouseMealSelectionView" owner:nil options:nil] firstObject];
    [self.mealSelectionView.nextMealButton addTarget:self action:@selector(nextMealPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.mealSelectionView.previousMealButton addTarget:self action:@selector(previousMealPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.mealSelectionView setMeal:self.currentlyDisplayedMeal];
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
            return [MITDiningMenuItemCell heightForMenuItem:self.currentlyDisplayedMeal.items[indexPath.row] tableViewWidth:self.tableView.frame.size.width];
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
        case kMITVenueDetailSectionMenu:
            return [self menuItemCellForIndexPath:indexPath];
            break;
        default:
            return [[UITableViewCell alloc] init];
            break;
    }
}

- (UITableViewCell *)venueInfoCell
{
    MITDiningHouseVenueInfoCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITDiningHouseVenueInfoCell];
    [cell setHouseVenue:self.houseVenue];
    cell.delegate = self;
    return cell;
}

- (UITableViewCell *)menuItemCellForIndexPath:(NSIndexPath *)indexPath
{
    MITDiningMenuItemCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITDiningMenuItemCell forIndexPath:indexPath];
    [cell setMenuItem:self.currentlyDisplayedMeal.items[indexPath.row]];
    
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

- (void)updateMealSelection
{
    self.mealSelectionView.meal = self.currentlyDisplayedMeal;
    self.currentlyDisplayedDay = self.currentlyDisplayedMeal.houseDay;
    self.currentlyDisplayedDate = self.self.currentlyDisplayedDay.date;
    
    self.mealSelectionView.nextMealButton.enabled = ([self.sortedMeals indexOfObject:self.currentlyDisplayedMeal] + 1 < self.sortedMeals.count);
    self.mealSelectionView.previousMealButton.enabled = ([self.sortedMeals indexOfObject:self.currentlyDisplayedMeal] > 0);
    
    [self.tableView reloadData];
}

- (void)nextMealPressed:(id)sender
{
    self.currentlyDisplayedMeal = self.sortedMeals[[self.sortedMeals indexOfObject:self.currentlyDisplayedMeal] + 1];

    [self updateMealSelection];
}

- (void)previousMealPressed:(id)sender
{
   self.currentlyDisplayedMeal = self.sortedMeals[[self.sortedMeals indexOfObject:self.currentlyDisplayedMeal] - 1];
    
    [self updateMealSelection];
}

#pragma mark - Setters/Getters
- (void)setHouseVenue:(MITDiningHouseVenue *)houseVenue
{
    _houseVenue = houseVenue;
    self.currentlyDisplayedDate = [NSDate date];
    self.currentlyDisplayedDay = [self.houseVenue houseDayForDate:self.currentlyDisplayedDate];
    self.sortedMeals = nil; // Force Recalculation
    
    [self updateMealSelection];
}

- (NSArray *)sortedMeals
{
    if (!_sortedMeals) {
        _sortedMeals = [self.houseVenue sortedMealsInWeek];
    }
    return _sortedMeals;
}

@end
