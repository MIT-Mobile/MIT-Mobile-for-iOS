#import "DiningHallMenuViewController.h"
#import "DiningMenuCompareViewController.h"
#import "DiningMenuFilterViewController.h"
#import "DiningHallDetailHeaderView.h"
#import "DiningHallMenuFooterView.h"
#import "DiningHallMenuItemTableCell.h"
#import "DiningHallMenuSectionHeaderView.h"
#import "DiningModule.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"

@interface DiningHallMenuViewController ()

@property (nonatomic, strong) NSArray * filtersApplied;
@property (nonatomic, strong) NSArray * mealItems;

@property (nonatomic, strong) NSDictionary * currentMeal;

@end

@implementation DiningHallMenuViewController

- (NSArray *) debugData
{
    NSDictionary *item1 = @{@"type": @"kosher", @"title" : @"kosher dinner", @"subtitle" : @"lemon chicken with pasta, green beans, yellow squash, tossed salad, fruit salad, stir fried tofu with spicy orange sauce", @"filters" : @[@1, @2, @3, @4]};
    NSDictionary *item2 = @{@"type": @"whirl wind", @"title" : @"thai curry", @"subtitle" : @"a spicy green thai curry sauce with snow peas, shiitake mushrooms, onions, red peppers, broccoli, and scallions", @"filters" : @[@3, @4]};
    NSDictionary *item3 = @{@"type": @"deli +", @"title" : @"baked potato bar", @"subtitle" : @"butter, sour cream, cheese sauce, veggie chili, chili, jalapenos, broccoli, and more", @"filters" : @[@1, @3, @4]};
    
    return @[item1, item2, item3];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    DiningHallDetailHeaderView *headerView = [[DiningHallDetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 87)];
    headerView.titleLabel.text = self.hallData[@"name"];
    
    NSDictionary *meal = [self getMealOfInterest];
    
//    NSDictionary *timeData = [DiningModule dayScheduleFromHours:self.hallData[@"hours"]];
//    if ([timeData[@"isOpen"] boolValue]) {
//        headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#008800"];
//    } else {
//        headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#bb0000"];
//    }
//    headerView.timeLabel.text = timeData[@"text"];
    
    self.tableView.tableHeaderView = headerView;
    
    DiningHallMenuFooterView *footerView = [[DiningHallMenuFooterView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 54)];
    self.tableView.tableFooterView = footerView;
    
    UIBarButtonItem *filterItem = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStylePlain target:self action:@selector(filterMenu:)];
    self.navigationItem.rightBarButtonItem = filterItem;
    
    self.tableView.allowsSelection = NO;
}

- (NSDictionary *) getMealOfInterest
{
    // finds the current meal or upcoming meal
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *currentDate = [NSDate date];
    NSString *dateString = [dateFormatter stringFromDate:currentDate];
    for (NSDictionary *day in self.hallData[@"meals_by_day"]) {
        if ([day[@"date"] isEqualToString:dateString]) {
            // may want to cache today's meal data
            NSDictionary *lastMeal;
            for (NSDictionary * meal in day[@"meals"]) {
                lastMeal = meal;
                NSDate *startDate = [NSDate dateForTodayFromTimeString:meal[@"start_time"]];
                NSDate *endDate = [NSDate dateForTodayFromTimeString:meal[@"end_time"]];
                if ([startDate compare:currentDate] == NSOrderedAscending && [currentDate compare:endDate] == NSOrderedAscending) {
                    // current meal
                    return meal;
                }
            }
            return lastMeal; // last meal in day
        }
    }
    
    return nil;
}

- (NSString *) timeSpanStringForMeal:(NSDictionary *) meal
{
    // returns meal start time and end time formatted
    //      hh:mma - hh:mma
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hh:mma"];
    NSDate *startDate = [NSDate dateForTodayFromTimeString:meal[@"start_time"]];
    NSDate *endDate = [NSDate dateForTodayFromTimeString:meal[@"end_time"]];
    
    return [NSString stringWithFormat:@"%@ - %@", [dateFormatter stringFromDate:startDate], [dateFormatter stringFromDate:endDate]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeLeft) {
        return YES;
    }
    return NO;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    DiningMenuCompareViewController *vc = [[DiningMenuCompareViewController alloc] init];
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [self presentViewController:vc animated:YES completion:NULL];
}

#pragma mark - Filter
- (void) filterMenu:(id)sender
{
    DiningMenuFilterViewController *filterVC = [[DiningMenuFilterViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [filterVC setFilters:self.filtersApplied];
    filterVC.delegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:filterVC];
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navController.navigationBar.barStyle = UIBarStyleBlack;
    
    [self presentViewController:navController animated:YES completion:NULL];
}

- (void) applyFilters:(NSArray *)filters
{
    self.filtersApplied = filters;
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self debugData] count];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *itemDict  = [self debugData][indexPath.row];
    return [DiningHallMenuItemTableCell cellHeightForCellWithStation:itemDict[@"type"] title:itemDict[@"title"] description:itemDict[@"subtitle"]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    DiningHallMenuItemTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[DiningHallMenuItemTableCell alloc] initWithReuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *itemDict  = [self debugData][indexPath.row];
    cell.station.text       = itemDict[@"type"];
    cell.title.text         = itemDict[@"title"];
    cell.description.text   = itemDict[@"subtitle"];
    cell.dietaryTypes       = itemDict[@"filters"];
    
    return cell;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        DiningHallMenuSectionHeaderView *header = [[DiningHallMenuSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), 56)];
        header.currentFilters = self.filtersApplied;
        return header;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *) tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        CGFloat height = 56;
        if ([self.filtersApplied count] > 0) {
            height+=30;
        }
        
        return height;
    }
    return 0;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
