#import "DiningHallMenuViewController.h"
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
#import "MITNavigationController.h"

@interface DiningHallMenuViewController () <DiningMenuFilterDelegate, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic,weak) IBOutlet UITableView *tableView;
@property (nonatomic,weak) IBOutlet UIView *compareContainerView;

@property (nonatomic, strong) UIBarButtonItem *filterBarButton;
@property (nonatomic, strong) NSSet * filtersApplied;
@property (nonatomic, strong) NSArray * mealItems;

@property (nonatomic, strong) DiningMeal * currentMeal;
@property (nonatomic, strong) DiningDay * currentDay;
@property (nonatomic, strong) NSDate * currentDate;
@property (nonatomic, strong) NSString * currentDateString;

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic,weak) DiningMenuCompareViewController *comparisonVC;

@end


static NSString * DiningFiltersUserDefaultKey = @"dining.filters";

@implementation DiningHallMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) setCurrentMeal:(DiningMeal *)currentMeal
{
    _currentMeal = currentMeal;
    [self updateMealReference];     // update mealReference to to match currentMeal
}

- (void) updateMealReference
{
    NSDate *date = (self.currentMeal.startTime) ? self.currentMeal.startTime : self.currentDay.date;
    _mealRef = [MealReference referenceWithMealName:self.currentMeal.name onDate:date];
}

- (void) setMealRef:(MealReference *)mealRef
{
    _mealRef = mealRef;
    // update current meal to closest meal to meal ref.
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"day.houseVenue.name ==[c] %@ AND startTime >= %@", self.venue.name, mealRef.date];
    NSArray *results = [CoreDataManager objectsForEntity:@"DiningMeal" matchingPredicate:predicate sortDescriptors:@[sort]];
    
    if ([results count]) {
        self.currentMeal = [results firstObject];
        self.currentDate = self.currentMeal.startTime;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.tableView.backgroundView = nil;
        self.tableView.backgroundColor = [UIColor colorWithHexString:@"#e1e3e8"];
    } else {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    NSArray *defaultFilterNames = [[NSUserDefaults standardUserDefaults] objectForKey:DiningFiltersUserDefaultKey];
    self.filtersApplied = (defaultFilterNames)?[DiningDietaryFlag flagsWithNames:defaultFilterNames]:nil;
    
    
    self.title = self.venue.shortName;
    
    // set current date string
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    self.currentDateString = [dateFormatter stringFromDate:[NSDate date]];
    
    self.currentDate = [NSDate date];
    
    // set current meal
    self.currentDay = [self.venue dayForDate:self.currentDate];
    self.currentMeal = [self.currentDay bestMealForDate:self.currentDate];
    
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
    
    if ([self.venue isOpenNow]) {
        headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#009900"];
    } else {
        headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#d20000"];
    }
    headerView.timeLabel.text = [self.currentDay statusStringRelativeToDate:[NSDate date]];
    
    [headerView.infoButton addTarget:self action:@selector(infoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    headerView.infoButton.hidden = NO;
    headerView.starButton.hidden = YES;
    
    self.tableView.tableHeaderView = headerView;
    
    DiningHallMenuFooterView *footerView = [[DiningHallMenuFooterView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 54)];
    footerView.backgroundColor = [UIColor whiteColor];
    self.tableView.tableFooterView = footerView;
    
    self.filterBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStylePlain target:self action:@selector(filterMenu:)];
    self.navigationItem.rightBarButtonItem = self.filterBarButton;
    
    self.tableView.allowsSelection = NO;
}

- (void) infoButtonPressed:(id) sender
{
    DiningHallInfoViewController *infoVC = [[DiningHallInfoViewController alloc] initWithStyle:UITableViewStyleGrouped];
    infoVC.venue = self.venue;
    
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Rotation
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if (self.comparisonVC) {
        return UIInterfaceOrientationLandscapeLeft;
    } else {
        return UIInterfaceOrientationPortrait;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if (UIDeviceOrientationIsLandscape(toInterfaceOrientation)) {
        DiningMenuCompareViewController *comparisonViewController = [[DiningMenuCompareViewController alloc] init];
        comparisonViewController.filtersApplied = self.filtersApplied;
        comparisonViewController.mealRef = self.mealRef;
        
        [self addChildViewController:comparisonViewController];
        UIView *comparisonView = comparisonViewController.view;
        [self.compareContainerView addSubview:comparisonView];
        self.comparisonVC = comparisonViewController;
    
        comparisonView.translatesAutoresizingMaskIntoConstraints = NO;
        id viewBindings = @{@"compareView" : comparisonView};
        [self.compareContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[compareView]|"
                                                                                          options:0
                                                                                          metrics:nil
                                                                                            views:viewBindings]];
        [self.compareContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[compareView]|"
                                                                                          options:0
                                                                                          metrics:nil
                                                                                            views:viewBindings]];
        
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [UIView transitionFromView:self.tableView
                            toView:self.compareContainerView
                          duration:duration
                           options:(UIViewAnimationOptionOverrideInheritedOptions |
                                    UIViewAnimationOptionShowHideTransitionViews |
                                    UIViewAnimationOptionTransitionCrossDissolve)
                        completion:^(BOOL finished) {
                            [comparisonViewController didMoveToParentViewController:self];
                        }];
    } else {
        DiningMenuCompareViewController *comparisonViewController = self.comparisonVC;
        self.mealRef = [comparisonViewController visibleMealReference];
        
        [comparisonViewController willMoveToParentViewController:nil];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        
        [UIView transitionFromView:self.compareContainerView
                            toView:self.tableView
                          duration:duration
                           options:(UIViewAnimationOptionShowHideTransitionViews)
                        completion:^(BOOL finished) {
                            [comparisonViewController.view removeFromSuperview];
                            [comparisonViewController removeFromParentViewController];
                            self.comparisonVC = nil;
                        }];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    if (UIDeviceOrientationIsLandscape(fromInterfaceOrientation)) {
        [self reloadMealInfo];
    }
}

#pragma mark - MealReference Delegate
- (void)reloadMealInfo
{
    [self fetchItemsForMeal:self.currentMeal withFilters:self.filtersApplied];
    [self.tableView reloadData];
}

#pragma mark - Filter
- (void) filterMenu:(id)sender
{
    DiningMenuFilterViewController *filterVC = [[DiningMenuFilterViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [filterVC setFilters:self.filtersApplied];
    filterVC.delegate = self;
    
    UINavigationController *navController = [[MITNavigationController alloc] initWithRootViewController:filterVC];
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navController.navigationBar.barStyle = UIBarStyleDefault;
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        navController.navigationBar.barStyle = UIBarStyleBlack;
    }
    
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

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor whiteColor];
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
        if (!self.currentMeal) {
            cell.textLabel.text = @"Closed";
        } else if (self.currentMeal && [self.currentMeal.items count] != 0 && [self.filtersApplied count] > 0) {
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
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
    NSInteger orderIndex = (self.currentMeal) ? [MEAL_ORDER indexOfObject:[self.currentMeal.name lowercaseString]] : 0;   // if currentMeal is nil, pretend we are first meal of day
    NSInteger mealIndex = (self.currentMeal) ? [self.currentDay.meals indexOfObject:self.currentMeal] : 0;
    if (orderIndex == 0 || [self.currentDay.meals count] == 1 || mealIndex == 0) {
        // need to get last meal of previous day, or nil if previous day has no meals
        NSDate *dayBefore = (self.currentDay) ? [self.currentDay.date dayBefore] : [self.currentDate dayBefore];
        self.currentDay = [self.venue dayForDate:dayBefore];
        self.currentDate = dayBefore;
        if (self.currentDay && [self.currentDay.meals count] > 0) {
            self.currentMeal = [self.currentDay.meals lastObject];  // get last meal in day
        } else {
            self.currentMeal = nil;
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
    [self.tableView reloadData];
}

- (void) pageRight
{
    NSInteger orderIndex = (self.currentMeal) ? [MEAL_ORDER indexOfObject:[self.currentMeal.name lowercaseString]] : [MEAL_ORDER count] - 1; // if currentMeal is nil, pretend we are last meal of day
    NSInteger mealIndex = (self.currentMeal) ? [self.currentDay.meals indexOfObject:self.currentMeal] : 0;
    if (orderIndex == [MEAL_ORDER count] - 1 || [self.currentDay.meals count] == 1 || mealIndex == [self.currentDay.meals count] - 1) {
        // need to get first meal of next day, or nil if next day has no meals
        NSDate *dayAfter = (self.currentDay) ? [self.currentDay.date dayAfter] : [self.currentDate dayAfter];
        self.currentDay = [self.venue dayForDate:dayAfter];
        self.currentDate = dayAfter;
        if (self.currentDay && [self.currentDay.meals count] > 0) {
            self.currentMeal = self.currentDay.meals[0];  // get last meal in day
        } else {
            self.currentMeal = nil;
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
    [self.tableView reloadData];
}

- (BOOL) canPageLeft
{
    NSArray * days = [[self.venue.menuDays allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
    NSInteger mealIndex = [self.currentDay.meals indexOfObject:self.currentMeal];
    
    if ([days indexOfObject:self.currentDay] == 0 && (mealIndex == NSNotFound || mealIndex == 0)) {
        return NO;
    }
    return YES;
}

- (BOOL) canPageRight
{
    NSArray * days = [[self.venue.menuDays allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
    NSInteger mealIndex = [self.currentDay.meals indexOfObject:self.currentMeal];
    
    if ([days indexOfObject:self.currentDay] == 0 && (mealIndex == NSNotFound || mealIndex >= [self.currentDay.meals count] - 1)) {
        return NO;
    }
    
    return YES;
}


@end
