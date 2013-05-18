#import "DiningHallMenuViewController.h"
#import "DiningMenuCompareViewController.h"
#import "DiningHallInfoViewController.h"
#import "DiningMenuFilterViewController.h"
#import "DiningHallDetailHeaderView.h"
#import "DiningHallMenuFooterView.h"
#import "DiningHallMenuItemTableCell.h"
#import "DiningHallMenuSectionHeaderView.h"
#import "DiningModule.h"
#import "HouseVenue.h"
#import "DiningDay.h"
#import "DiningMeal.h"
#import "DiningMealItem.h"
#import "DiningDietaryFlag.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "UIImageView+WebCache.h"

@interface DiningHallMenuViewController ()

@property (nonatomic, strong) UIBarButtonItem *filterBarButton;
@property (nonatomic, strong) NSSet * filtersApplied;
@property (nonatomic, strong) NSArray * mealItems;
@property (nonatomic, strong) NSDictionary * hallStatus;

@property (nonatomic, strong) DiningMeal * currentMeal;
@property (nonatomic, strong) DiningDay * currentDay;
@property (nonatomic, strong) NSDate * currentDate;
@property (nonatomic, strong) NSString * currentDateString;

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end


static NSString * DiningFiltersUserDefaultKey = @"dining.filters";

@implementation DiningHallMenuViewController

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
    
    NSArray *defaultFilterNames = [[NSUserDefaults standardUserDefaults] objectForKey:DiningFiltersUserDefaultKey];
    self.filtersApplied = [DiningDietaryFlag flagsFromNames:defaultFilterNames];
    
    
    self.title = self.venue.shortName;
    
    // set current date string
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    self.currentDateString = [dateFormatter stringFromDate:[NSDate date]];
    
    self.currentDate = [HouseVenue fakeDate];
    
    // set current meal
    self.currentMeal = [self.venue bestMealForDate:self.currentDate];
    self.currentDay = [self.venue dayForDate:self.currentDate];
    
    self.fetchedResultsController = [self fetchedResultsControllerForMeal:self.currentMeal filters:self.filtersApplied];
    self.fetchedResultsController.delegate = self;
    
    [self.fetchedResultsController performFetch:nil];
    
    DiningHallDetailHeaderView *headerView = [[DiningHallDetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 87)];
    headerView.titleLabel.text = self.venue.name;
    
    __weak DiningHallDetailHeaderView *weakHeaderView = headerView;
    [headerView.iconView setImageWithURL:[NSURL URLWithString:self.venue.iconURL]
                               completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        [weakHeaderView layoutIfNeeded];
    }];
    
    self.hallStatus = [self hallStatusStringForMeal:self.currentMeal];
    if ([self.hallStatus[@"isOpen"] boolValue]) {
        headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#008800"];
    } else {
        headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#bb0000"];
    }
    headerView.timeLabel.text = self.hallStatus[@"text"];
    
    [headerView.accessoryButton setImage:[UIImage imageNamed:@"dining/info.png"] forState:UIControlStateNormal];
    [headerView.accessoryButton setImage:[UIImage imageNamed:@"dining/info-pressed.png"] forState:UIControlStateHighlighted];
    [headerView.accessoryButton addTarget:self action:@selector(infoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    self.tableView.tableHeaderView = headerView;
    
    DiningHallMenuFooterView *footerView = [[DiningHallMenuFooterView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 54)];
    self.tableView.tableFooterView = footerView;
    
    self.filterBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStylePlain target:self action:@selector(filterMenu:)];
    self.navigationItem.rightBarButtonItem = self.filterBarButton;
    
    self.tableView.allowsSelection = NO;
}

- (void) infoButtonPressed:(id) sender
{
    DiningHallInfoViewController *infoVC = [[DiningHallInfoViewController alloc] initWithStyle:UITableViewStyleGrouped];
    infoVC.venue = self.venue;
    infoVC.hallStatus = self.hallStatus;
    
    [self.navigationController pushViewController:infoVC animated:YES];
}

- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    _managedObjectContext.persistentStoreCoordinator = [[CoreDataManager coreDataManager] persistentStoreCoordinator];
    _managedObjectContext.undoManager = nil;
    _managedObjectContext.stalenessInterval = 0;
    
    return _managedObjectContext;
}

- (NSFetchedResultsController *)fetchedResultsControllerForMeal:(DiningMeal *)meal filters:(NSSet *)dietaryFilters {
    
    self.fetchedResultsController = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DiningMealItem"
                                              inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;
    fetchRequest.predicate = [self predicateForMeal:meal filteredBy:dietaryFilters];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"ordinality" ascending:YES];
    fetchRequest.sortDescriptors = @[sort];
        
    NSFetchedResultsController *fetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:self.managedObjectContext
                                          sectionNameKeyPath:nil
                                                   cacheName:nil];
    
    return fetchedResultsController;
}

- (void) fetchItemsForMeal:(DiningMeal *) meal withFilters:(NSSet *)dietaryFilters
{
    self.fetchedResultsController.fetchRequest.predicate = [self predicateForMeal:meal filteredBy:dietaryFilters];
    [self.fetchedResultsController performFetch:nil];
}

- (NSPredicate *) predicateForMeal:(DiningMeal *) meal filteredBy:(NSSet *) dietaryFilters
{
    // predicate is used in fetch request for DiningMealItems
    if (![dietaryFilters count]) {
        // no filters, predicate can be simple, also solves issue that no filters should be treated the same as all filters
        return [NSPredicate predicateWithFormat:@"meal = %@", meal];
    } else {
        return [NSPredicate predicateWithFormat:@"meal = %@ AND ANY dietaryFlags IN %@", meal, dietaryFilters];
    }
}

- (NSString *) timeSpanStringForMeal:(NSDictionary *) meal
{
    // returns meal start time and end time formatted
    //      h:mma - h:mma
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"h:mma"];
    NSDate *startDate = [NSDate dateForTodayFromTimeString:meal[@"start_time"]];
    NSDate *endDate = [NSDate dateForTodayFromTimeString:meal[@"end_time"]];
    
    return [NSString stringWithFormat:@"%@ - %@", [dateFormatter stringFromDate:startDate], [dateFormatter stringFromDate:endDate]];
}

- (NSDictionary *) hallStatusStringForMeal:(DiningMeal *) meal
{
//      Returns hall status relative to the curent time of day.
//      Return value is a dictionary with the structure
//          isOpen : YES/NO
//          text : @"User Facing String"
// Example return strings
//          - Closed for the day
//          - Opens at 5:30pm
//          - Open until 4:00pm

    NSDate *rightNow = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    
    if (!meal) {
        // closed with no hours today
        return @{@"isOpen": @NO,
                 @"text" : @"Closed for the day"};
    }
    
    if (meal.startTime && meal.endTime) {
        // need to calculate if the current time is before opening, before closing, or after closing
        
        BOOL willOpen       = ([meal.startTime compare:rightNow] == NSOrderedDescending); // openDate > rightNow , before the open hours for the day
        BOOL currentlyOpen  = ([meal.startTime compare:rightNow] == NSOrderedAscending && [rightNow compare:meal.endTime] == NSOrderedAscending);  // openDate < rightNow < closeDate , within the open hours
        BOOL hasClosed      = ([rightNow compare:meal.endTime] == NSOrderedDescending); // rightNow > closeDate , after the closing time for the day
        
        [dateFormat setDateFormat:@"h:mm a"];  // adjust format for pretty printing
        
        if (willOpen) {
            NSString *closedStringFormatted = [dateFormat stringFromDate:meal.startTime];
            return @{@"isOpen": @NO,
                     @"text" : [NSString stringWithFormat:@"Opens at %@", closedStringFormatted]};
            
        } else if (currentlyOpen) {
            NSString *openStringFormatted = [dateFormat stringFromDate:meal.endTime];
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
    vc.filtersApplied = self.filtersApplied;
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

- (void) applyFilters:(NSSet *)filters
{
    self.filtersApplied = filters;
    [self fetchItemsForMeal:self.currentMeal withFilters:self.filtersApplied];
    
    NSArray *filterNames = [[self.filtersApplied valueForKey:@"name"] allObjects];
    [[NSUserDefaults standardUserDefaults] setObject:filterNames forKey:DiningFiltersUserDefaultKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sections = [self.fetchedResultsController sections];
    if ([sections count] > 0) {
        id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:0];
        if ([sectionInfo numberOfObjects]) {
            return [sectionInfo numberOfObjects];
        } else {
            return 1;       // will be used to show 'No meals this day'
        }
    }
    return 0;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
    if ([sectionInfo numberOfObjects] == 0) {
        return 54;  // 'List empty' cells are static 54px
    }
    
    DiningMealItem *item = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (item) {
        return [DiningHallMenuItemTableCell cellHeightForCellWithStation:item.station title:item.name subtitle:item.subtitle];
    }
    return 54;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
    if ([sectionInfo numberOfObjects] == 0) {
        static NSString *EmptyCellIdentifier = @"ListEmptyCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:EmptyCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:EmptyCellIdentifier];
        }
        
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont systemFontOfSize:17];
        if (self.currentMeal && [self.filtersApplied count] > 0) {
            cell.textLabel.text = @"No matching items";
        } else {
            cell.textLabel.text = @"No meals this day";
        }
        
        return cell;
    } else {
        DiningMealItem *item = [self.fetchedResultsController objectAtIndexPath:indexPath];
        if (item) {
            static NSString *CellIdentifier = @"Cell";
            DiningHallMenuItemTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[DiningHallMenuItemTableCell alloc] initWithReuseIdentifier:CellIdentifier];
            }
            
            cell.station.text       = item.station;
            cell.title.text         = item.name;
            cell.subtitle.text      = item.subtitle;
            
            NSArray *imagePaths = [[item.dietaryFlags mapObjectsUsingBlock:^id(id obj) {
                return ((DiningDietaryFlag *)obj).pdfPath;
            }] allObjects];
            cell.dietaryImagePaths  = [imagePaths sortedArrayUsingSelector:@selector(compare:)];
            
            return cell;
        }
    }
    return nil;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        DiningHallMenuSectionHeaderView *header = [[DiningHallMenuSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), 56)]; // height does not matter here, calculated in heightForHeaderInSection: delegate
        
        NSString * mealString = [self.currentMeal.name capitalizedString];
        header.mainLabel.text = [DiningHallMenuSectionHeaderView stringForMeal:self.currentMeal onDate:self.currentDate];
        header.mealLabel.text = mealString;
        header.timeLabel.text = [self.currentMeal hoursSummary];
        
        [header.leftButton addTarget:self action:@selector(pageLeft) forControlEvents:UIControlEventTouchUpInside];
        [header.rightButton addTarget:self action:@selector(pageRight) forControlEvents:UIControlEventTouchUpInside];
        header.leftButton.enabled = [self canPageLeft];
        header.rightButton.enabled = [self canPageRight];

        
        header.currentFilters = [self.filtersApplied allObjects];
        
        if (!self.currentMeal) {
            header.showMealBar = NO;
        }
        
        return header;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *) tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        CGFloat height = [DiningHallMenuSectionHeaderView heightForPagerBar];
        if ([self.filtersApplied count] > 0) {
            height+=[DiningHallMenuSectionHeaderView heightForFilterBar];
        }
        
        if (self.currentMeal) {
            height+=[DiningHallMenuSectionHeaderView heightForMealBar];
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

#define MEAL_ORDER @[@"breakfast", @"brunch", @"lunch", @"dinner"]

- (void) pageLeft
{
    NSInteger orderIndex = (self.currentMeal) ? [MEAL_ORDER indexOfObject:self.currentMeal.name] : 0;   // if currentMeal is null, pretend we are first meal of day
    NSInteger mealIndex = (self.currentMeal) ? [self.currentDay.meals indexOfObject:self.currentMeal] : 0;
    if (orderIndex == 0 || [self.currentDay.meals count] == 1 || mealIndex == 0) {
        // need to get last meal of previous day, or nil if previous day has no meals
        NSDate *dayBefore = (self.currentDay) ? [self.currentDay.date dayBefore] : [self.currentDate dayBefore];
        self.currentDay = [self.venue dayForDate:dayBefore];
        self.currentDate = dayBefore;
        self.currentMeal = nil;
        if (self.currentDay) {
            if ([self.currentDay.meals count]) {
                self.currentMeal = [self.currentDay.meals lastObject];  // get last meal in day
            }
        }
    } else {
        // need to get previous meal in same day
        DiningMeal * meal = nil;
        NSInteger offset = 1;
        while (!meal && orderIndex - offset >= 0) {
            meal = [self.currentDay mealWithName:MEAL_ORDER[orderIndex - offset]];
            offset++;
        }
        self.currentMeal = meal;
    }
    
    [self fetchItemsForMeal:self.currentMeal withFilters:self.filtersApplied];
    self.filterBarButton.enabled = (self.currentMeal) ? YES : NO;       // enable/disable filter button if meal is valid
    [self.tableView reloadData];
}

- (void) pageRight
{
    NSInteger orderIndex = (self.currentMeal) ? [MEAL_ORDER indexOfObject:self.currentMeal.name] : [MEAL_ORDER count] - 1; // if currentMeal is null, pretend we are last meal of day
    NSInteger mealIndex = (self.currentMeal) ? [self.currentDay.meals indexOfObject:self.currentMeal] : 0;
    if (orderIndex == [MEAL_ORDER count] - 1 || [self.currentDay.meals count] == 1 || mealIndex == [self.currentDay.meals count] - 1) {
        // need to get first meal of next day, or nil if next day has no meals
        NSDate *dayAfter = (self.currentDay) ? [self.currentDay.date dayAfter] : [self.currentDate dayAfter];
        self.currentDay = [self.venue dayForDate:dayAfter];
        self.currentDate = dayAfter;
        self.currentMeal = nil;
        if (self.currentDay) {
            if ([self.currentDay.meals count]) {
                self.currentMeal = self.currentDay.meals[0];  // get last meal in day
            }
        }
    } else {
        DiningMeal * meal = nil;
        NSInteger offset = 1;
        while (!meal && orderIndex + offset < [MEAL_ORDER count]) {
            meal = [self.currentDay mealWithName:MEAL_ORDER[orderIndex + offset]];
            offset++;
        }
        self.currentMeal = meal;
    }
    
        
    [self fetchItemsForMeal:self.currentMeal withFilters:self.filtersApplied];
    self.filterBarButton.enabled = (self.currentMeal) ? YES : NO;       // enable/disable filter button if meal is valid
    [self.tableView reloadData];
}

- (BOOL) canPageLeft
{
    NSArray * days = [[self.venue.menuDays allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
    NSInteger mealIndex = [self.currentDay.meals indexOfObject:self.currentMeal];
    
    if ([days indexOfObject:self.currentDay] == 0 && mealIndex == 0) {
        return NO;
    }
    return YES;
}

- (BOOL) canPageRight
{
    NSArray * days = [[self.venue.menuDays allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
    NSInteger mealIndex = [self.currentDay.meals indexOfObject:self.currentMeal];
    
    if ([days indexOfObject:self.currentDay] == 0 && mealIndex == [self.currentDay.meals count] - 1) {
        return NO;
    }
    
    return YES;
}



@end
