#import "MITDiningHouseMealListViewController.h"
#import "MITDiningMenuItem.h"
#import "MITDiningMenuItemCell.h"
#import "MITDiningFiltersCell.h"
#import "MITDiningMeal.h"

static NSString *const kMITDiningMenuItemCell = @"MITDiningMenuItemCell";
static NSString *const kMITDiningFiltersCell = @"MITDiningFiltersCell";

@interface MITDiningHouseMealListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSSet *filters;
@property (nonatomic, strong) NSArray *currentlyDisplayedItems;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;

@end

@implementation MITDiningHouseMealListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupTableView];
    [self setupNotificationLabel];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateCurrentlyDisplayedItems];
}

- (void)setMeal:(MITDiningMeal *)meal
{
    _meal = meal;
    [self updateCurrentlyDisplayedItems];
}

#pragma mark - NotificationLabel

- (void)setupNotificationLabel
{
    self.notificationLabel.font = [UIFont systemFontOfSize:24.0];
    self.notificationLabel.textColor = [UIColor grayColor];
    self.notificationLabel.hidden = YES;
    [self.notificationLabel sizeToFit];
}

- (void)updateNotificationLabel
{
    if (self.meal) {
        if (self.currentlyDisplayedItems.count == 0) {
            if (self.meal.items.count > 0) {
                self.notificationLabel.text = @"No Matching Items";
            } else {
                self.notificationLabel.text = @"No Items";
            }
            self.notificationLabel.hidden = NO;
        } else {
            self.notificationLabel.hidden = YES;
        }
    } else {
        self.notificationLabel.text = @"Closed";
        self.notificationLabel.hidden = NO;
    }
}

#pragma mark - Table view data source

- (void)setupTableView
{
    UINib *cellNib = [UINib nibWithNibName:kMITDiningMenuItemCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITDiningMenuItemCell];
    
    cellNib = [UINib nibWithNibName:kMITDiningFiltersCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITDiningFiltersCell];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self hasFiltersApplied]) {
        if (indexPath.row == 0) {
            return [MITDiningFiltersCell heightForFilters:self.filters tableViewWidth:self.tableView.frame.size.width];
        } else {
            return [MITDiningMenuItemCell heightForMenuItem:self.currentlyDisplayedItems[indexPath.row - 1] tableViewWidth:self.tableView.frame.size.width];
        }
    } else {
        return [MITDiningMenuItemCell heightForMenuItem:self.currentlyDisplayedItems[indexPath.row] tableViewWidth:self.tableView.frame.size.width];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self hasFiltersApplied]) {
        return self.currentlyDisplayedItems.count + 1;
    } else {
        return self.currentlyDisplayedItems.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self hasFiltersApplied] && indexPath.row == 0) {
        return [self filtersCell];
    } else {
        return [self menuItemCellForIndexPath:indexPath];
    }
}

- (UITableViewCell *)menuItemCellForIndexPath:(NSIndexPath *)indexPath
{
    MITDiningMenuItemCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITDiningMenuItemCell];
    NSInteger index = [self hasFiltersApplied] ? indexPath.row - 1 : indexPath.row;
    [cell setMenuItem:self.currentlyDisplayedItems[index]];
    
    return cell;
}

- (UITableViewCell *)filtersCell
{
    MITDiningFiltersCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITDiningFiltersCell];
    [cell setFilters:self.filters];
    
    return cell;
}

#pragma mark - Filtering

- (void)applyFilters:(NSSet *)filters
{
    self.filters = filters;
    [self updateCurrentlyDisplayedItems];
}

- (void)updateCurrentlyDisplayedItems
{
    if (self.filters.count == 0) {
        self.currentlyDisplayedItems = [self.meal.items array];
    }
    else {
        NSMutableArray *filteredItems = [[NSMutableArray alloc] init];
        for (MITDiningMenuItem *item in self.meal.items) {
            if (item.dietaryFlags) {
                for (NSString *dietaryFlag in (NSArray *)item.dietaryFlags) {
                    if ([self.filters containsObject:dietaryFlag]) {
                        [filteredItems addObject:item];
                        break;
                    }
                }
            }
        }
        self.currentlyDisplayedItems = filteredItems;
    }
    
    if (self.currentlyDisplayedItems.count > 0) {
        // Show empty cells -- normal tableView behavior
        self.tableView.tableFooterView = nil;
    } else {
        // Hide empty cells so label is more visible -- Can't hide tableview or filters will be hidden as well.
        self.tableView.tableFooterView = [UIView new];
    }

    [self.tableView reloadData];
    
    [self updateNotificationLabel];
}

- (BOOL)hasFiltersApplied
{
    return (self.filters.count > 0);
}

@end
