#import "MITDiningMenuComparisonViewController.h"
#import "MITDiningHallMenuComparisonNoMealsCell.h"
#import "MITDiningHallMenuComparisonCell.h"
#import "MITDiningHallMenuComparisonView.h"
#import "MITDiningComparisonDataManager.h"
#import "Foundation+MITAdditions.h"
#import "MITDiningAggregatedMeal.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningHouseDay.h"
#import "MITDiningMenuItem.h"
#import "MITDiningMeal.h"
#import "MITAdditions.h"

#define SECONDS_IN_DAY 86400
#define DAY_VIEW_PADDING 5      // padding on each side of day view. doubled when two views are adjacent

@interface MITDiningMenuComparisonViewController () <UIScrollViewDelegate, MITDiningCompareViewDelegate>

@property (nonatomic,weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic,weak) IBOutlet NSLayoutConstraint *topSpacingConstraint;

@property (nonatomic, weak) MITDiningHallMenuComparisonView *previousComparisonView;     // on left
@property (nonatomic, weak) MITDiningHallMenuComparisonView *currentComparisonView;      // center
@property (nonatomic, weak) MITDiningHallMenuComparisonView *nextComparisonView;         // on right


@property (nonatomic) NSInteger indexOfCurrentAggregateMeal;

@property (nonatomic, assign) BOOL pauseBeforeResettingScrollOffset;

@property (nonatomic, strong) MITDiningAggregatedMeal *aggregatedMeal;

@end

@implementation MITDiningMenuComparisonViewController

typedef NS_ENUM(NSInteger, MITPageDirection) {
    MITPageDirectionForward = 1,
    MITPageDirectionNone = 0,
    MITPageDirectionBackward = -1
};

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSDate *visibleDate = self.visibleMeal.houseDay.date;
    if (!visibleDate) {
        visibleDate = self.visibleDay.date;
    }
    self.indexOfCurrentAggregateMeal = [self.dataManager indexOfAggregatedMealForDate:visibleDate mealName:self.visibleMeal.name];
    
    self.aggregatedMeal =
    self.visibleAggregatedMeal = [self.dataManager aggregatedMeals][self.indexOfCurrentAggregateMeal];
    
    [self setupScrollView];
    [self setupComparisonViews];

    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
}

- (void)setupScrollView
{
    self.view.backgroundColor = [UIColor mit_backgroundColor];
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = [UIColor clearColor];
}

- (void)setupComparisonViews
{
    MITDiningHallMenuComparisonView *previous = [[MITDiningHallMenuComparisonView alloc] init];
    previous.delegate = self;
    [self.scrollView addSubview:previous];
    self.previousComparisonView = previous;
    
    MITDiningHallMenuComparisonView *current = [[MITDiningHallMenuComparisonView alloc] init];
    current.delegate = self;
    [self.scrollView addSubview:current];
    self.currentComparisonView = current;
    
    MITDiningHallMenuComparisonView *next = [[MITDiningHallMenuComparisonView alloc] init];
    next.delegate = self;
    [self.scrollView addSubview:next];
    self.nextComparisonView = next;
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.topSpacingConstraint.constant = 0;
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadData];
    
    // This is to handle the edge cases of the current paging system
    // At all times there must be 3 views and all 3 must have valid meal
    // references.
    // If we are at the far left edge of the current 'page' then we need to perform the following
    // transform on the views:
    //      |[previous(EMPTYMEALREFERENCE)]-[current(self.mealRef==startingMealReference)]-[next(nextMealRef0)]|
    // to
    //      |[previous(startingMealReference)]-[current(self.mealRef==nextMealRef0)]-[next(nextMealRef1)]|
    //
    // If we are on the far right:
    //      |[previous(previousMealRef0)]-[current(self.mealRef==startingMealReference)]-[next(EMPTYMEALREFERENCE)]|
    // to
    //      |[previous(previousMealRef1)]-[current(self.mealRef==previousMealRef0)]-[next(startingMealReference)]|
    //
    // In all cases, we need to end up visually centered on the view with the startingMealReference
    //
    self.visibleAggregatedMeal = self.aggregatedMeal;
    
    if (self.indexOfCurrentAggregateMeal == 0) {
        // Set the 'current'  meal reference (in this case, middle of the current page)
        // to the next meal..
        self.aggregatedMeal = [self aggregatedMealForMealInDirection:MITPageDirectionForward];
        
        //...and move the pointers around so everything is happy
        [self pagePointersRight];
    } else if (self.indexOfCurrentAggregateMeal >= self.dataManager.aggregatedMeals.count - 1) { // Same as the above, only in the opposite direction
        self.aggregatedMeal = [self aggregatedMealForMealInDirection:MITPageDirectionBackward];
        [self pagePointersLeft];
    } else {
        // This should only be triggered if our current meal reference is already
        // the centered meal. Nothing to do here but twiddle our thumbs.
    }
    
    // Force a view layout so we can make sure all of the subviews in the
    // scroll view are properly layed out (and scrolling to somewhere makes
    // a limited degree of sense)
    // TODO: Double-check and make sure our superview is in a sane place at this point.
    //  For now, just repeat the scroll in viewDidAppear:
    // (bskinner - 2014.03.02)
    [self reloadAllComparisonViews];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Just in case, recenter things again on the visible view. This most likely won't change a thing
    // but is here in case the view hierarchy was not stable the last time we tried to visibly center
    // the meal and everything (should) be set by now.
    [self scrollAggregateMealToVisible:self.visibleAggregatedMeal animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGSize contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds) * 3 , CGRectGetHeight(self.scrollView.bounds));
    self.scrollView.contentSize = contentSize;

    // (viewPadding * 2) is used because each view has own padding, so there are 2 padded spaces to account for
    CGSize comparisonSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds) - (DAY_VIEW_PADDING * 2), CGRectGetHeight(self.scrollView.bounds));
    
    self.previousComparisonView.frame = CGRectMake(DAY_VIEW_PADDING, 0, comparisonSize.width, comparisonSize.height);
    self.currentComparisonView.frame = CGRectMake(CGRectGetMaxX(self.previousComparisonView.frame) + (DAY_VIEW_PADDING * 2), 0, comparisonSize.width, comparisonSize.height);
    self.nextComparisonView.frame = CGRectMake(CGRectGetMaxX(self.currentComparisonView.frame) + (DAY_VIEW_PADDING * 2), 0, comparisonSize.width, comparisonSize.height);
}

- (BOOL)scrollAggregateMealToVisible:(MITDiningAggregatedMeal *)aggregateMeal animated:(BOOL)animated
{
    NSInteger index = NSNotFound;
    NSArray *views = @[self.previousComparisonView, self.currentComparisonView, self.nextComparisonView];

    index = [views indexOfObjectPassingTest:^BOOL(MITDiningHallMenuComparisonView *view, NSUInteger idx, BOOL *stop) {
        return [view.aggregateMeal isEqual:aggregateMeal];
    }];
    
    if (index != NSNotFound) {
        MITDiningHallMenuComparisonView *menuView = views[index];
        
        CGPoint targetPoint = CGRectInset(menuView.frame, -DAY_VIEW_PADDING, 0.).origin;
        
        [self.scrollView setContentOffset:targetPoint animated:animated];
        
        if (index > 0 && (index < views.count)) {
            MITDiningHallMenuComparisonView *previousView = views[index - 1];
            [previousView setScrollOffsetAgainstRightEdge];
        }

        return true;
    } else {
        return false;
    }
}

- (void) loadData
{
    self.currentComparisonView.aggregateMeal = self.aggregatedMeal;
    self.previousComparisonView.aggregateMeal = [self aggregatedMealForMealInDirection:MITPageDirectionBackward];
    self.nextComparisonView.aggregateMeal = [self aggregatedMealForMealInDirection:MITPageDirectionForward];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView   // called on finger up as we are moving
{
    scrollView.scrollEnabled = NO;      // [IPHONEAPP-663] needed to force touch response to inner scrollview on ComparisonView paging hasn't decelerated
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    scrollView.scrollEnabled = YES;
    BOOL shouldCenter = YES;    // unless we have hit edge of data, we should center the 3 comparison views
    MITDiningHallMenuComparisonView *viewToRecenter = self.currentComparisonView;
    
    // Handle infinite scroll between 3 views. Returns to center view so there is always a view on the left and right
    if (scrollView.contentOffset.x > scrollView.bounds.size.width) {
        // have scrolled to the right
        if ([self didReachEdgeInDirection:MITPageDirectionForward]) {
            shouldCenter = YES;
            viewToRecenter = self.nextComparisonView;
        } else {
            if (!self.nextComparisonView.isScrolling) {
                [self pagePointersRight];
            } else {
                shouldCenter = NO;
                self.pauseBeforeResettingScrollOffset = YES;    // need to wait to reset scroll offset to center DiningComparisonView until comparisonview stops scrolling. only an issue when fast scrolling happens (page, scroll) IPHONEAPP-663
            }
        }
        
    } else if (scrollView.contentOffset.x < scrollView.bounds.size.width) {
        // have scrolled to the left
        if ([self didReachEdgeInDirection:MITPageDirectionBackward]) {
            shouldCenter = YES;
            viewToRecenter = self.previousComparisonView;
        } else {
            if (!self.previousComparisonView.isScrolling) {
                [self pagePointersLeft];
            } else {
                shouldCenter = NO;
                self.pauseBeforeResettingScrollOffset = YES;    // need to wait to reset scroll offset to center DiningComparisonView until comparisonview stops scrolling. only an issue when fast scrolling happens (page, scroll) IPHONEAPP-663
            }
        }
    }
    
    if (shouldCenter) {
        CGRect contentFrame = CGRectInset(viewToRecenter.frame, -DAY_VIEW_PADDING, 0);
        [scrollView setContentOffset:contentFrame.origin animated:NO]; // return to center view to give illusion of infinite scroll
        self.visibleAggregatedMeal = viewToRecenter.aggregateMeal;
    }
}

- (BOOL) didReachEdgeInDirection:(MITPageDirection)direction
{
    return ((self.indexOfCurrentAggregateMeal - 1 <= 0 && direction == MITPageDirectionBackward) ||
            (self.indexOfCurrentAggregateMeal + 1 >= self.dataManager.aggregatedMeals.count - 1 && direction == MITPageDirectionForward));
}

# pragma mark - Paging
- (void) pagePointersRight
{
    self.previousComparisonView.aggregateMeal = self.currentComparisonView.aggregateMeal;

    self.currentComparisonView.aggregateMeal = self.nextComparisonView.aggregateMeal;
        self.aggregatedMeal = self.currentComparisonView.aggregateMeal;
    
    [self.currentComparisonView setScrollOffset:self.nextComparisonView.contentOffset animated:NO];
    [self.nextComparisonView resetScrollOffset];
    [self.previousComparisonView setScrollOffsetAgainstRightEdge];
  
    self.indexOfCurrentAggregateMeal++;

    self.nextComparisonView.aggregateMeal = [self aggregatedMealForMealInDirection:MITPageDirectionForward];

    [self reloadAllComparisonViews];
}

- (void) pagePointersLeft
{
    self.nextComparisonView.aggregateMeal = self.currentComparisonView.aggregateMeal;
    
    self.currentComparisonView.aggregateMeal = self.previousComparisonView.aggregateMeal;
    self.aggregatedMeal = self.currentComparisonView.aggregateMeal;
    
    [self.currentComparisonView setScrollOffset:self.previousComparisonView.contentOffset animated:NO];
    [self.previousComparisonView setScrollOffsetAgainstRightEdge];
    [self.nextComparisonView resetScrollOffset];
    
    self.indexOfCurrentAggregateMeal--;

    self.previousComparisonView.aggregateMeal = [self aggregatedMealForMealInDirection:MITPageDirectionBackward];

    [self reloadAllComparisonViews];
}

- (void) reloadAllComparisonViews
{
    [self.previousComparisonView reloadData];
    [self.currentComparisonView reloadData];
    [self.nextComparisonView reloadData];
}
#pragma mark - DiningCompareViewDelegate
- (NSString *) titleForCompareView:(MITDiningHallMenuComparisonView *)compareView
{
    return compareView.aggregateMeal.mealDisplayTitle;
}

- (NSInteger) numberOfSectionsInCompareView:(MITDiningHallMenuComparisonView *)compareView
{
    return compareView.aggregateMeal.venues.count;
}

- (NSString *) compareView:(MITDiningHallMenuComparisonView *)compareView titleForSection:(NSInteger)section
{
    return [compareView.aggregateMeal.venues[section] shortName];
}

- (NSString *) compareView:(MITDiningHallMenuComparisonView *)compareView subtitleForSection:(NSInteger)section
{
    MITDiningMeal *meal = [compareView.aggregateMeal mealForHouseVenue:compareView.aggregateMeal.venues[section]];
    return meal.mealHoursDescription;
}

- (NSInteger) compareView:(MITDiningHallMenuComparisonView *)compareView numberOfItemsInSection:(NSInteger) section
{
    MITDiningMeal *meal = [compareView.aggregateMeal mealForHouseVenue:compareView.aggregateMeal.venues[section]];
    NSArray *filteredItems = [self filteredItemsForMeal:meal];
    return filteredItems.count > 0 ? filteredItems.count : 1;
}

- (UICollectionViewCell *) compareView:(MITDiningHallMenuComparisonView *)compareView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITDiningMeal *meal = [compareView.aggregateMeal mealForHouseVenue:compareView.aggregateMeal.venues[indexPath.section]];
    NSArray *filteredItems = [self filteredItemsForMeal:meal];
    if (filteredItems.count > 0) {
        MITDiningMenuItem *item = filteredItems[indexPath.row];
        
        MITDiningHallMenuComparisonCell *cell = [compareView dequeueReusableCellWithReuseIdentifier:@"DiningMenuCell" forIndexPath:indexPath];
        cell.primaryLabel.text = item.name;
        cell.primaryLabel.textAlignment = NSTextAlignmentLeft;
        cell.secondaryLabel.text = item.itemDescription;
        cell.dietaryTypes = item.dietaryFlags;
        return cell;
    }
    else {
        MITDiningHallMenuComparisonNoMealsCell *cell = [compareView dequeueReusableCellWithReuseIdentifier:@"DiningMenuNoMealsCell" forIndexPath:indexPath];
        cell.primaryLabel.text = @"closed";
        
        return cell;
    }
}

- (CGFloat) compareView:(MITDiningHallMenuComparisonView *)compareView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITDiningMeal *meal = [compareView.aggregateMeal mealForHouseVenue:compareView.aggregateMeal.venues[indexPath.section]];
    
    NSArray *filteredItems = [self filteredItemsForMeal:meal];
    if (filteredItems.count > 0) {
        MITDiningMenuItem *item = filteredItems[indexPath.row];
        return [MITDiningHallMenuComparisonCell heightForComparisonCellOfWidth:compareView.columnWidth
                                                               withPrimaryText:item.name
                                                                 secondaryText:item.itemDescription
                                                               numDietaryTypes:[item.dietaryFlags count]];
    }
    else {
        return 30;
    }
}

- (void) compareViewDidEndDecelerating:(MITDiningHallMenuComparisonView *)compareView
{
    if (self.pauseBeforeResettingScrollOffset) {
        if (self.previousComparisonView == compareView) {
            [self pagePointersLeft];
        } else if (self.nextComparisonView == compareView) {
            [self pagePointersRight];
        }

        [self.scrollView setContentOffset:CGPointMake(CGRectGetMinX(self.currentComparisonView.frame) - DAY_VIEW_PADDING, 0) animated:NO]; // return to center view to give illusion of infinite scroll
        self.pauseBeforeResettingScrollOffset = NO;
    }
}

- (MITDiningAggregatedMeal *)aggregatedMealForMealInDirection:(MITPageDirection)direction
{
    if ((self.indexOfCurrentAggregateMeal == 0 && direction == MITPageDirectionBackward) ||
        (self.indexOfCurrentAggregateMeal == self.dataManager.aggregatedMeals.count - 1 && direction == MITPageDirectionForward)) {
        return nil;
    }
    
    switch (direction) {
        case MITPageDirectionForward:
            return self.dataManager.aggregatedMeals[self.indexOfCurrentAggregateMeal + 1];
            break;
        case MITPageDirectionBackward:
            return self.dataManager.aggregatedMeals[self.indexOfCurrentAggregateMeal - 1];
            break;
        default:
            return self.dataManager.aggregatedMeals[self.indexOfCurrentAggregateMeal];
            break;
    }
}

- (NSArray *)filteredItemsForMeal:(MITDiningMeal *)meal
{
    if (self.filtersApplied.count == 0) {
        return meal.items.array;
    }
    else {
        NSMutableArray *filteredItems = [[NSMutableArray alloc] init];
        for (MITDiningMenuItem *item in meal.items) {
            if (item.dietaryFlags) {
                for (NSString *dietaryFlag in (NSArray *)item.dietaryFlags) {
                    if ([self.filtersApplied containsObject:dietaryFlag]) {
                        [filteredItems addObject:item];
                        break;
                    }
                }
            }
        }
        return filteredItems;
    }
}

#pragma mark Setters/Getters

- (void)setHouseVenues:(NSArray *)houseVenues
{
    _houseVenues = houseVenues;
    self.dataManager.houseVenues = _houseVenues;
}

- (MITDiningComparisonDataManager *)dataManager
{
    if (!_dataManager)
    {
        _dataManager = [[MITDiningComparisonDataManager alloc] init];
    }
    return _dataManager;
}

@end
