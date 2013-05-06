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
@property (nonatomic, strong) NSString * currentDateString;

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
    
    // set current date string
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    self.currentDateString = [dateFormatter stringFromDate:[NSDate date]];
    
    // set current meal
    self.currentMeal = [self mealOfInterestForCurrentDay];
    
    DiningHallDetailHeaderView *headerView = [[DiningHallDetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 87)];
    headerView.titleLabel.text = self.hallData[@"name"];
    
    NSDictionary *timeData = [self hallStatusStringForMeal:self.currentMeal];
    if ([timeData[@"isOpen"] boolValue]) {
        headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#008800"];
    } else {
        headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#bb0000"];
    }
    headerView.timeLabel.text = timeData[@"text"];
    self.tableView.tableHeaderView = headerView;
    
    DiningHallMenuFooterView *footerView = [[DiningHallMenuFooterView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 54)];
    self.tableView.tableFooterView = footerView;
    
    UIBarButtonItem *filterItem = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStylePlain target:self action:@selector(filterMenu:)];
    self.navigationItem.rightBarButtonItem = filterItem;
    
    self.tableView.allowsSelection = NO;
}

- (NSDictionary *) mealOfInterestForCurrentDay
{
    // gets current meal the closest meal
    NSDate *currentDate = [NSDate date];
    
    NSArray *meals = [self mealsForDay:self.currentDateString];
    if (meals) {
        for (int i = 0; i < [meals count]; i++) {
            NSDictionary * meal = meals[i];
            NSDate *startDate = [NSDate dateForTodayFromTimeString:meal[@"start_time"]];
            NSDate *endDate = [NSDate dateForTodayFromTimeString:meal[@"end_time"]];
            if ([startDate compare:currentDate] == NSOrderedAscending && [currentDate compare:endDate] == NSOrderedAscending) {
                // current meal. current time is within meal time
                return meal;
            } else if ([currentDate compare:startDate] == NSOrderedAscending) {
                // current time is before start time
                return meal;
            } else if ([endDate compare:currentDate] == NSOrderedAscending) {
                // current time is after meal's end time. see if meal is last in day
                if (i == [meals count] - 1) {
                    // return this meal only if it is the last in the day
                    return meal;
                }
            }
        }
    }
    return nil;
}


- (NSArray *) mealsForDay:(NSString *) dateString
{
    // method returns array or nil if day does not have any meals or matching day cannot be found
    
    // date string must be in the yyyy-MM-dd format to match data
    for (NSDictionary *day in self.hallData[@"meals_by_day"]) {
        if ([day[@"date"] isEqualToString:dateString]) {
            // we have found our day, return meals
            return day[@"meals"];
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

- (NSDictionary *) hallStatusStringForMeal:(NSDictionary *) meal
{
    NSDate *rightNow = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    
    if (!meal) {
        // closed with no hours today
        return @{@"isOpen": @NO,
                 @"text" : @"Closed for the day"};
    }
    
    if (meal[@"start_time"] && meal[@"end_time"]) {
        // need to calculate if the current time is before opening, before closing, or after closing
        [dateFormat setDateFormat:@"HH:mm"];
        NSString * openString   = meal[@"start_time"];
        NSString * closeString    = meal[@"end_time"];
        
        NSDate *openDate = [NSDate dateForTodayFromTimeString:openString];
        NSDate *closeDate = [NSDate dateForTodayFromTimeString:closeString];
        
        BOOL willOpen       = ([openDate compare:rightNow] == NSOrderedDescending); // openDate > rightNow , before the open hours for the day
        BOOL currentlyOpen  = ([openDate compare:rightNow] == NSOrderedAscending && [rightNow compare:closeDate] == NSOrderedAscending);  // openDate < rightNow < closeDate , within the open hours
        BOOL hasClosed      = ([rightNow compare:closeDate] == NSOrderedDescending); // rightNow > closeDate , after the closing time for the day
        
        [dateFormat setDateFormat:@"h:mm a"];  // adjust format for pretty printing
        
        if (willOpen) {
            NSString *closedStringFormatted = [dateFormat stringFromDate:openDate];
            return @{@"isOpen": @NO,
                     @"text" : [NSString stringWithFormat:@"Opens at %@", closedStringFormatted]};
            
        } else if (currentlyOpen) {
            NSString *openStringFormatted = [dateFormat stringFromDate:closeDate];
            return @{@"isOpen": @YES,
                     @"text" : [NSString stringWithFormat:@"Open until %@", openStringFormatted]};
        } else if (hasClosed) {
            return @{@"isOpen": @NO,
                     @"text" : @"Closed for the day"};
        }
    }
    
    // the just in case
    return @{@"isOpen": @NO,
             @"text" : @"Closed for the day"};
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
    NSArray *mealItems = self.currentMeal[@"items"];
    return [mealItems count];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *mealItems = self.currentMeal[@"items"];
    NSDictionary *itemDict  = mealItems[indexPath.row];
    return [DiningHallMenuItemTableCell cellHeightForCellWithStation:itemDict[@"station"] title:itemDict[@"name"] description:itemDict[@"description"]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    DiningHallMenuItemTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[DiningHallMenuItemTableCell alloc] initWithReuseIdentifier:CellIdentifier];
    }
    
    NSArray *mealItems = self.currentMeal[@"items"];
    NSDictionary *itemDict  = mealItems[indexPath.row];
    cell.station.text       = itemDict[@"station"];
    cell.title.text         = itemDict[@"name"];
    cell.description.text   = itemDict[@"description"];
    cell.dietaryTypes       = itemDict[@"dietary_flags"];
    
    return cell;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        DiningHallMenuSectionHeaderView *header = [[DiningHallMenuSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), 56)];
        [header.leftButton addTarget:self action:@selector(pageLeft) forControlEvents:UIControlEventTouchUpInside];
        [header.rightButton addTarget:self action:@selector(pageRight) forControlEvents:UIControlEventTouchUpInside];
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


#pragma mark - Paging between meals
- (void) pageLeft
{
    NSLog(@"Page Left");
}

- (void) pageRight
{
    NSLog(@"Page Right");
}



@end
