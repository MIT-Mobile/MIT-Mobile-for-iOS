#import "MITDiningHouseVenueDetailViewController.h"
#import "MITDiningHouseVenueInfoViewController.h"
#import "MITDiningMenuComparisonViewController.h"
#import "MITDiningHouseMealSelectionView.h"
#import "MITDiningComparisonDataManager.h"
#import "MITDiningFilterViewController.h"
#import "MITDiningVenueInfoCell.h"
#import "MITDiningAggregatedMeal.h"
#import "Foundation+MITAdditions.h"
#import "MITDiningMenuItemCell.h"
#import "MITDiningFiltersCell.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningMenuItem.h"
#import "MITDiningHouseDay.h"
#import "MITDiningVenues.h"
#import "MITDiningMeal.h"
#import "MITDiningHouseMealListViewController.h"

typedef NS_ENUM(NSInteger, kMITVenueDetailSection) {
    kMITVenueDetailSectionInfo,
    kMITVenueDetailSectionMenu
};

static NSString *const kMITDiningHouseVenueInfoCell = @"MITDiningVenueInfoCell";
static NSString *const kMITDiningMenuItemCell = @"MITDiningMenuItemCell";
static NSString *const kMITDiningFiltersCell = @"MITDiningFiltersCell";

static NSString *const kMITDiningFiltersUserDefaultsKey = @"kMITDiningFiltersUserDefaultsKey";

@interface MITDiningHouseVenueDetailViewController () <UIScrollViewDelegate, MITDiningHouseVenueInfoCellDelegate, MITDiningFilterDelegate, UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, strong) MITDiningMeal *currentlyDisplayedMeal;
@property (nonatomic, strong) MITDiningHouseDay *currentlyDisplayedDay;

@property (nonatomic, strong) NSArray *currentlyDisplayedItems;
@property (nonatomic, strong) NSArray *sortedMeals;
@property (nonatomic, strong) NSSet *filters;

@property (nonatomic, weak) IBOutlet UIView *mealsContainerView;
@property (nonatomic, strong) UIView *venueInfoView;
@property (nonatomic, strong) MITDiningHouseMealSelectionView *mealSelectionView;

@property (weak, nonatomic) IBOutlet UIView *comparisonContainerView;
@property (nonatomic, strong) MITDiningMenuComparisonViewController *comparisonViewController;

@property (nonatomic, strong) UIPageViewController *mealsPageViewController;
@end

@implementation MITDiningHouseVenueDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupNavigationBar];
    
    NSDate *currentDate = [NSDate date];
    MITDiningHouseDay *day = [self.houseVenue houseDayForDate:currentDate];
    self.currentlyDisplayedMeal = [day bestMealForDate:currentDate];
    self.currentlyDisplayedDay = [self.houseVenue houseDayForDate:currentDate];
    
    CGFloat height = [MITDiningVenueInfoCell heightForHouseVenue:self.houseVenue tableViewWidth:self.view.bounds.size.width];
    [self.mealsContainerView addSubview:self.venueInfoView];
    [self.mealsContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[venueInfoView(==venueInfoViewHeight)]" options:0 metrics:@{@"venueInfoViewHeight": [NSNumber numberWithFloat:height]} views:@{@"venueInfoView": self.venueInfoView}]];
    [self.mealsContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[venueInfoView]-0-|" options:0 metrics:nil views:@{@"venueInfoView": self.venueInfoView}]];
    
    self.mealSelectionView = [[[NSBundle mainBundle] loadNibNamed:@"MITDiningHouseMealSelectionView" owner:nil options:nil] firstObject];
    self.mealSelectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mealSelectionView.nextMealButton addTarget:self action:@selector(nextMealPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.mealSelectionView.previousMealButton addTarget:self action:@selector(previousMealPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.mealSelectionView setMeal:self.currentlyDisplayedMeal forDay:self.currentlyDisplayedDay];
    [self.mealsContainerView addSubview:self.mealSelectionView];
    
    [self.mealsContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[venueInfoView]-0-[mealSelectionView(==mealSelectionViewHeight)]" options:0 metrics:@{@"mealSelectionViewHeight": @(54)} views:@{@"venueInfoView": self.venueInfoView,
                                                                                                                                                       @"mealSelectionView": self.mealSelectionView}]];
    [self.mealsContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[mealSelectionView]-0-|" options:0 metrics:nil views:@{@"mealSelectionView": self.mealSelectionView}]];
    
    [self setupPageViewController];
    
    [self applyFilters:[NSSet setWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kMITDiningFiltersUserDefaultsKey]]];
}

- (UIView *)venueInfoView
{
    if (!_venueInfoView) {
        MITDiningVenueInfoCell *cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MITDiningVenueInfoCell class]) owner:self options:nil] objectAtIndex:0]; //[self.tableView dequeueReusableCellWithIdentifier:kMITDiningHouseVenueInfoCell];
        
        [cell setHouseVenue:self.houseVenue];
        cell.delegate = self;
        _venueInfoView = cell;
    }
    
    return _venueInfoView;
}

- (void)setupNavigationBar
{
    UIBarButtonItem *filterButton = [[UIBarButtonItem alloc] initWithTitle:@"Filters" style:UIBarButtonItemStylePlain target:self action:@selector(showFilterSelector)];
    self.navigationItem.rightBarButtonItem = filterButton;
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)setupPageViewController
{
    self.mealsPageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.mealsPageViewController.delegate = self;
    self.mealsPageViewController.dataSource = self;
    
    [self addChildViewController:self.mealsPageViewController];
    self.mealsPageViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mealsContainerView addSubview:self.mealsPageViewController.view];
    [self.mealsPageViewController didMoveToParentViewController:self];
    
    [self.mealsContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[mealSelectionView]-0-[mealsPageViewControllerView]-0-|" options:0 metrics:nil views:@{@"mealSelectionView": self.mealSelectionView,
                                                                                                                                                                 @"mealsPageViewControllerView": self.mealsPageViewController.view}]];
    [self.mealsContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[mealsPageViewControllerView]-0-|" options:0 metrics:nil views:@{@"mealsPageViewControllerView": self.mealsPageViewController.view}]];
    
    NSDate *currentDate = [NSDate date];
    MITDiningHouseDay *day = [self.houseVenue houseDayForDate:currentDate];
    MITDiningMeal *currentMeal = [day bestMealForDate:currentDate];
    
    MITDiningHouseMealListViewController *currentMealListViewController = [[MITDiningHouseMealListViewController alloc] init];
    currentMealListViewController.meal = currentMeal;
    currentMealListViewController.day = day;
    
    [self.mealsPageViewController setViewControllers:@[currentMealListViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (MITDiningHouseMealListViewController *)listViewControllerAtIndex:(NSInteger)index
{
    MITDiningHouseMealListViewController *viewController = [[MITDiningHouseMealListViewController alloc] initWithNibName:nil bundle:nil];
    viewController.meal = self.sortedMeals[index];
    [viewController applyFilters:self.filters];
    return viewController;
}

#pragma mark - PageView

- (void)replaceCurrentPageViewMealListControllerWithNewMealListController:(MITDiningHouseMealListViewController *)newMealListVC direction:(UIPageViewControllerNavigationDirection)direction
{
    // I swear this is necessary or UIPageViewController breaks when swiping/clicking buttons too fast
    // See: http://stackoverflow.com/a/17330606/1260141
    __block MITDiningHouseVenueDetailViewController *blockSelf = self;
    NSArray *listViewControllers = @[newMealListVC];
    [self.mealsPageViewController setViewControllers:listViewControllers direction:direction animated:YES completion:^(BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [blockSelf.mealsPageViewController setViewControllers:listViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
        });
    }];
}

#pragma mark - UIPageViewDataSource Methods

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    MITDiningHouseMealListViewController *current = (MITDiningHouseMealListViewController *)[self.mealsPageViewController.viewControllers firstObject];
    MITDiningHouseMealListViewController *previous = [self previousViewControllerForCurrentMeal:current.meal andCurrentDay:current.day];
    return previous;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    MITDiningHouseMealListViewController *current = (MITDiningHouseMealListViewController *)[self.mealsPageViewController.viewControllers firstObject];
    MITDiningHouseMealListViewController *next = [self nextViewControllerForCurrentMeal:current.meal andCurrentDay:current.day];
    return next;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    NSUInteger count = 0;
    for (MITDiningHouseDay *day in self.houseVenue.mealsByDay) {
        if (day.sortedMealsArray.count > 0) {
            count += day.sortedMealsArray.count;
        } else {
            // If there's no meals, an empty day still shows which means any day counts for at least one.
            count += 1;
        }
    }
    return count;
}

#pragma mark - UIPageViewDelegate Methods

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    MITDiningHouseMealListViewController *newMealList = (MITDiningHouseMealListViewController *)[pageViewController.viewControllers firstObject];
    
    self.currentlyDisplayedMeal = newMealList.meal;
    self.currentlyDisplayedDay = newMealList.day;
    
    [self updateMealSelectionView];
}

- (BOOL)shouldEnableNextMealButton
{
    MITDiningHouseDay *lastDay = self.houseVenue.mealsByDay.lastObject;
    if (self.currentlyDisplayedMeal) {
        return ![lastDay.sortedMealsArray.lastObject isEqual:self.currentlyDisplayedMeal];
    } else {
        return ![lastDay isEqual:self.currentlyDisplayedDay];
    }
}

- (BOOL)shouldEnablePreviousMealButton
{
    MITDiningHouseDay *firstDay = self.houseVenue.mealsByDay.firstObject;
    if (self.currentlyDisplayedDay) {
        return ![firstDay.sortedMealsArray.firstObject isEqual:self.currentlyDisplayedMeal];
    } else {
        return ![firstDay isEqual:self.currentlyDisplayedDay];
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    MITDiningHouseMealListViewController *newListViewController = (MITDiningHouseMealListViewController *)[pendingViewControllers firstObject];
    [newListViewController applyFilters:self.filters];
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
}

#pragma mark - Venue Info Cell Delegate

- (void)infoCellDidPressInfoButton:(MITDiningVenueInfoCell *)infoCell
{
    MITDiningHouseVenueInfoViewController *infoVC = [[MITDiningHouseVenueInfoViewController alloc] init];
    infoVC.houseVenue = self.houseVenue;
    
    [self.navigationController pushViewController:infoVC animated:YES];
}

#pragma mark - Meal Selection View

- (void)updateMealSelectionView
{
    [self.mealSelectionView setMeal:self.currentlyDisplayedMeal forDay:self.currentlyDisplayedDay];
    
    self.mealSelectionView.nextMealButton.enabled = [self shouldEnableNextMealButton];
    self.mealSelectionView.previousMealButton.enabled = [self shouldEnablePreviousMealButton];
}

- (void)nextMealPressed:(id)sender
{
    MITDiningHouseMealListViewController *next = [self nextViewControllerForCurrentMeal:self.currentlyDisplayedMeal andCurrentDay:self.currentlyDisplayedDay];
    if (!next) {
        return;
    }
    self.currentlyDisplayedMeal = next.meal;
    self.currentlyDisplayedDay = next.day;
    [self updateMealSelectionView];
    
    [self replaceCurrentPageViewMealListControllerWithNewMealListController:next direction:UIPageViewControllerNavigationDirectionForward];
}

- (void)previousMealPressed:(id)sender
{
    MITDiningHouseMealListViewController *previous = [self previousViewControllerForCurrentMeal:self.currentlyDisplayedMeal andCurrentDay:self.currentlyDisplayedDay];
    if (!previous) {
        return;
    }
    self.currentlyDisplayedMeal = previous.meal;
    self.currentlyDisplayedDay = previous.day;
    [self updateMealSelectionView];
    
    [self replaceCurrentPageViewMealListControllerWithNewMealListController:previous direction:UIPageViewControllerNavigationDirectionReverse];
}

#pragma mark - Previous / Next Meal List View Controllers

- (MITDiningHouseMealListViewController *)nextViewControllerForCurrentMeal:(MITDiningMeal *)meal andCurrentDay:(MITDiningHouseDay *)day
{
    MITDiningHouseMealListViewController *next = nil;
    
    if (meal && ![day.sortedMealsArray.lastObject isEqual:meal]) {
        NSUInteger idx = [day.sortedMealsArray indexOfObject:meal];
        
        if (idx != NSNotFound && idx < day.sortedMealsArray.count) {
            next = [[MITDiningHouseMealListViewController alloc] initWithNibName:nil bundle:nil];
            next.meal = day.sortedMealsArray[idx + 1];
            next.day = day;
        }
    } else if (![self.houseVenue.mealsByDay.lastObject isEqual:day]) {
        NSUInteger idx = [self.houseVenue.mealsByDay indexOfObject:day];
        
        if (idx != NSNotFound && idx < self.houseVenue.mealsByDay.count) {
            next = [[MITDiningHouseMealListViewController alloc] initWithNibName:nil bundle:nil];
            next.day = self.houseVenue.mealsByDay[idx + 1];
            next.meal = next.day.sortedMealsArray.firstObject;
        }
    }
    
    [next applyFilters:self.filters];
    
    return next;
}

- (MITDiningHouseMealListViewController *)previousViewControllerForCurrentMeal:(MITDiningMeal *)meal andCurrentDay:(MITDiningHouseDay *)day
{
    MITDiningHouseMealListViewController *previous = nil;
    
    if (meal && ![day.sortedMealsArray.firstObject isEqual:meal]) {
        NSUInteger idx = [day.sortedMealsArray indexOfObject:meal];
        
        if (idx != NSNotFound && idx != 0) {
            previous = [[MITDiningHouseMealListViewController alloc] initWithNibName:nil bundle:nil];
            previous.meal = day.sortedMealsArray[idx - 1];
            previous.day = day;
        }
    } else if (![self.houseVenue.mealsByDay.firstObject isEqual:day]) {
        NSUInteger idx = [self.houseVenue.mealsByDay indexOfObject:day];
        
        if (idx != NSNotFound && idx != 0) {
            previous = [[MITDiningHouseMealListViewController alloc] initWithNibName:nil bundle:nil];
            previous.day = self.houseVenue.mealsByDay[idx - 1];
            previous.meal = previous.day.sortedMealsArray.lastObject;
        }
    }
    
    [previous applyFilters:self.filters];
    
    return previous;
}

#pragma mark - Setters/Getters

- (void)setHouseVenue:(MITDiningHouseVenue *)houseVenue
{
    _houseVenue = houseVenue;
    self.title = self.houseVenue.shortName;
    self.sortedMeals = nil; // Force Recalculation
    
    [self updateMealSelectionView];
}

- (NSArray *)sortedMeals
{
    if (!_sortedMeals) {
        _sortedMeals = [self.houseVenue sortedMealsInWeek];
    }
    return _sortedMeals;
}

#pragma mark - Filtering

- (void)showFilterSelector
{
    MITDiningFilterViewController *filterVC = [[MITDiningFilterViewController alloc] init];
    [filterVC setSelectedFilters:self.filters];
    filterVC.delegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:filterVC] animated:YES completion:NULL];
}

- (void)applyFilters:(NSSet *)filters
{
    self.filters = filters;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:filters.allObjects forKey:kMITDiningFiltersUserDefaultsKey];
    [defaults synchronize];
    MITDiningHouseMealListViewController *currentListViewController = (MITDiningHouseMealListViewController *)[self.mealsPageViewController.viewControllers firstObject];
    [currentListViewController applyFilters:self.filters];
}

#pragma mark - Landscape Comparison VC

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        self.comparisonViewController = [[MITDiningMenuComparisonViewController alloc] init];
        self.comparisonViewController.houseVenues = [self.houseVenue.venues.house array];
        self.comparisonViewController.filtersApplied = self.filters;
        
        self.comparisonViewController.visibleDay = self.currentlyDisplayedDay;
        self.comparisonViewController.visibleMeal = self.currentlyDisplayedMeal;
        
        [self addChildViewController:self.comparisonViewController];
        UIView *comparisonView = self.comparisonViewController.view;
        [self.comparisonContainerView addSubview:comparisonView];
        
        comparisonView.translatesAutoresizingMaskIntoConstraints = NO;
        id viewBindings = @{@"compareView" : comparisonView};
        [self.comparisonContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[compareView]|"
                                                                                             options:0
                                                                                             metrics:nil
                                                                                               views:viewBindings]];
        [self.comparisonContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[compareView]|"
                                                                                             options:0
                                                                                             metrics:nil
                                                                                               views:viewBindings]];
        
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [UIView transitionFromView:self.mealsContainerView
                            toView:self.comparisonContainerView
                          duration:duration
                           options:(UIViewAnimationOptionOverrideInheritedOptions |
                                    UIViewAnimationOptionShowHideTransitionViews |
                                    UIViewAnimationOptionTransitionCrossDissolve)
                        completion:^(BOOL finished) {
                            [self.comparisonViewController didMoveToParentViewController:self];
                        }];
    } else {
        
        self.currentlyDisplayedMeal = [self.comparisonViewController.dataManager mealForAggregatedMeal:self.comparisonViewController.visibleAggregatedMeal inVenue:self.houseVenue];
        
        // Can't reliably set from self.currentlyDisplayedMeal.houseDay because meal might be nil
        for (MITDiningHouseDay *houseDay in self.houseVenue.mealsByDay) {
            if ([houseDay.date isEqualToDateIgnoringTime:self.comparisonViewController.visibleAggregatedMeal.date]) {
                self.currentlyDisplayedDay = houseDay;
                break;
            }
        }
        
        MITDiningHouseMealListViewController *currentMealList = self.mealsPageViewController.viewControllers.firstObject;
        if (![currentMealList.meal isEqual:self.currentlyDisplayedMeal] || ![currentMealList.day isEqual:self.currentlyDisplayedDay]) {
            MITDiningHouseMealListViewController *new = [[MITDiningHouseMealListViewController alloc] initWithNibName:nil bundle:nil];
            new.meal = self.currentlyDisplayedMeal;
            new.day = self.currentlyDisplayedDay;
            
            [self replaceCurrentPageViewMealListControllerWithNewMealListController:new direction:UIPageViewControllerNavigationDirectionForward];
        }
        
        
        [self.comparisonViewController willMoveToParentViewController:nil];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        
        [UIView transitionFromView:self.comparisonContainerView
                            toView:self.mealsContainerView
                          duration:duration
                           options:(UIViewAnimationOptionShowHideTransitionViews)
                        completion:^(BOOL finished) {
                            [self.comparisonViewController.view removeFromSuperview];
                            [self.comparisonViewController removeFromParentViewController];
                            self.comparisonViewController = nil;
                            [self updateMealSelectionView];
                        }];
    }
}

@end