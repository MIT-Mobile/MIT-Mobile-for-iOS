#import "DiningMenuCompareViewController.h"
#import "DiningHallMenuCompareView.h"
#import "CoreDataManager.h"
#import "Foundation+MITAdditions.h"

#import "HouseVenue.h"
#import "DiningDay.h"
#import "DiningMeal.h"
#import "DiningMealItem.h"

#define SECONDS_IN_DAY 86400
#define DAY_VIEW_PADDING 5      // padding on each side of day view. doubled when two views are adjacent
#define MEAL_ORDER @[@"breakfast", @"brunch", @"lunch", @"dinner"]


@interface NSFetchedResultsController (DiningComparisonAdditions)

- (void) fetchItemsForPredicate:(NSPredicate *)predicate;

@end

@implementation NSFetchedResultsController (DiningComparisonAdditions)

- (void) fetchItemsForPredicate:(NSPredicate *)predicate
{
    self.fetchRequest.predicate = predicate;
    
    NSError *error = nil;
    [self performFetch:&error];
    
    if (error) {
        NSLog(@"Error fetching DiningMealItems. \n %@", error);
    }
}
@end



@interface DiningMenuCompareViewController () <UIScrollViewDelegate, DiningCompareViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) NSDateFormatter *sectionSubtitleFormatter;

@property (nonatomic, strong) DiningHallMenuCompareView * previous;     // on left
@property (nonatomic, strong) DiningHallMenuCompareView * current;      // center
@property (nonatomic, strong) DiningHallMenuCompareView * next;         // on right

@property (nonatomic, strong) NSArray * houseVenueSections;     // array of houseVenueSection titles, needed because fetchedResultsController will not return empty sections

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *previousFRC;
@property (nonatomic, strong) NSFetchedResultsController *currentFRC;
@property (nonatomic, strong) NSFetchedResultsController *nextFRC;

@property (nonatomic, assign) BOOL pauseBeforeResettingScrollOffset;

@end

@implementation DiningMenuCompareViewController

typedef enum {
    // used in paging logic
    kPageDirectionForward = 1,
    kPageDirectionNone = 0,
    kPageDirectionBackward = -1
} MealPageDirection;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews = YES;
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"shortName" ascending:YES];
    NSArray *houseVenues = [CoreDataManager objectsForEntity:@"HouseVenue" matchingPredicate:nil sortDescriptors:@[sort]];
    self.houseVenueSections = [houseVenues valueForKey:@"shortName"];

    // The scrollview has a frame that is just larger than the viewcontrollers view bounds so that padding can be seen between scrollable pages.
    // Frames are also inverted (height => width, width => height) because when the view loads the rotation has not yet occurred.
    CGRect frame;
    if ([[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] integerValue] >= 6) {
        frame = CGRectMake(-DAY_VIEW_PADDING, 0, CGRectGetHeight(self.view.bounds) + (DAY_VIEW_PADDING * 2), CGRectGetWidth(self.view.bounds));
    } else {
        // iOS 5 and iOS 6 differ on the size of the status bar at this point in time.
        CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        frame = CGRectMake(-DAY_VIEW_PADDING, 0, CGRectGetHeight(self.view.bounds) + (DAY_VIEW_PADDING * 2) + statusBarHeight, CGRectGetWidth(self.view.bounds) - statusBarHeight);
    }
    
    self.sectionSubtitleFormatter = [[NSDateFormatter alloc] init];
    [self.sectionSubtitleFormatter setAMSymbol:@"am"];
    [self.sectionSubtitleFormatter setPMSymbol:@"pm"];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:frame];
    self.scrollView.delegate = self;
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds) * 3, CGRectGetHeight(self.scrollView.bounds));
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    
    [self.view addSubview:self.scrollView];
    
    CGSize comparisonSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds) - (DAY_VIEW_PADDING * 2), CGRectGetHeight(self.scrollView.bounds));
	self.previous = [[DiningHallMenuCompareView alloc] initWithFrame:CGRectMake(DAY_VIEW_PADDING, 0, comparisonSize.width, comparisonSize.height)];
    self.current = [[DiningHallMenuCompareView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.previous.frame) + (DAY_VIEW_PADDING * 2), 0, comparisonSize.width, comparisonSize.height)];
    self.next = [[DiningHallMenuCompareView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.current.frame) + (DAY_VIEW_PADDING * 2), 0, comparisonSize.width, comparisonSize.height)];
                                                                        // (viewPadding * 2) is used because each view has own padding, so there are 2 padded spaces to account for
    
    self.previous.delegate = self;
    self.current.delegate = self;
    self.next.delegate = self;
    
    [self.scrollView addSubview:self.previous];
    [self.scrollView addSubview:self.current];
    [self.scrollView addSubview:self.next];
    
    // offset if on edge of list
    if ([self didReachEdgeInDirection:kPageDirectionBackward]) {
        // should center on previous view and have current meal ref be one ahead
        self.mealRef = [self mealReferenceForMealInDirection:kPageDirectionForward];
        [self.scrollView setContentOffset:CGPointMake(self.previous.frame.origin.x - DAY_VIEW_PADDING, 0) animated:NO];  // have to subtract DAY_VIEW_PADDING because scrollview sits offscreen at offset.
    } else if ([self didReachEdgeInDirection:kPageDirectionForward]) {
        // should center on next view and have current meal ref be one behind
        self.mealRef = [self mealReferenceForMealInDirection:kPageDirectionBackward];
        [self.scrollView setContentOffset:CGPointMake(self.next.frame.origin.x - DAY_VIEW_PADDING, 0) animated:NO];  // have to subtract DAY_VIEW_PADDING because scrollview sits offscreen at offset.
        [self.current setScrollOffsetAgainstRightEdge];
    } else {
        [self.scrollView setContentOffset:CGPointMake(self.current.frame.origin.x - DAY_VIEW_PADDING, 0) animated:NO];  // have to subtract DAY_VIEW_PADDING because scrollview sits offscreen at offset.
        [self.previous setScrollOffsetAgainstRightEdge];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [self loadData];
    [self reloadAllComparisonViews];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Rotation
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        return YES;
    }
    return NO;
}

#pragma mark - Model methods

- (void) loadData
{
    // load data for current collection view, set meal pointers
    self.currentFRC = [self fetchedResultsControllerForMealReference:self.mealRef];
    [self.currentFRC performFetch:nil];
    self.current.mealRef = self.mealRef;
    
    // loadData for left collectionView
    MealReference *mRef = [self mealReferenceForMealInDirection:kPageDirectionBackward];
    self.previousFRC = [self fetchedResultsControllerForMealReference:mRef];
    [self.previousFRC performFetch:nil];
    self.previous.mealRef = mRef;
    
    // load data for right collectionView
    mRef = [self mealReferenceForMealInDirection:kPageDirectionForward];
    self.nextFRC = [self fetchedResultsControllerForMealReference:mRef];
    [self.nextFRC performFetch:nil];
    self.next.mealRef = mRef;
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

- (NSFetchedResultsController *)fetchedResultsControllerForMealReference:(MealReference *)ref
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DiningMealItem"
                                              inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;
    fetchRequest.predicate = [self predicateForMealNamed:ref.name onDate:ref.date];
    NSString *sectionKeyPath = @"meal.day.houseVenue.shortName";
    NSSortDescriptor *sectionSort = [NSSortDescriptor sortDescriptorWithKey:sectionKeyPath ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"ordinality" ascending:YES];
    fetchRequest.sortDescriptors = @[sectionSort, sort];
    
    NSFetchedResultsController *fetchedResultsController =
                    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                        managedObjectContext:self.managedObjectContext
                                                          sectionNameKeyPath:sectionKeyPath
                                                                   cacheName:ref.cacheName];
    return fetchedResultsController;
}

- (NSPredicate *) predicateForMealNamed:(NSString *)mealName onDate:(NSDate *)date
{
    if (![self.filtersApplied count]) {
        return [NSPredicate predicateWithFormat:@"self.meal.name = %@ AND self.meal.day.date >= %@ AND self.meal.day.date <= %@", mealName, [date startOfDay], [date endOfDay]];
    } else {
        return [NSPredicate predicateWithFormat:@"self.meal.name = %@ AND ANY dietaryFlags IN %@ AND self.meal.day.date >= %@ AND self.meal.day.date <= %@", mealName, self.filtersApplied, [date startOfDay], [date endOfDay]];
    }
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
    
    // Handle infinite scroll between 3 views. Returns to center view so there is always a view on the left and right
    if (scrollView.contentOffset.x > scrollView.frame.size.width) {
        // have scrolled to the right
        if ([self didReachEdgeInDirection:kPageDirectionForward]) {
            shouldCenter = NO;
        } else {
            if (!self.next.isScrolling) {
                [self pagePointersRight];
            } else {
                shouldCenter = NO;
                self.pauseBeforeResettingScrollOffset = YES;    // need to wait to reset scroll offset to center DiningComparisonView until comparisonview stops scrolling. only an issue when fast scrolling happens (page, scroll) IPHONEAPP-663
            }
        }
        
    } else if (scrollView.contentOffset.x < scrollView.frame.size.width) {
        // have scrolled to the left
        if ([self didReachEdgeInDirection:kPageDirectionBackward]) {
            shouldCenter = NO;
        } else {
            if (!self.previous.isScrolling) {
                [self pagePointersLeft];
            } else {
                shouldCenter = NO;
                self.pauseBeforeResettingScrollOffset = YES;    // need to wait to reset scroll offset to center DiningComparisonView until comparisonview stops scrolling. only an issue when fast scrolling happens (page, scroll) IPHONEAPP-663
            }
        }
    }
    
    if (shouldCenter) {
        [scrollView setContentOffset:CGPointMake(self.current.frame.origin.x - DAY_VIEW_PADDING, 0) animated:NO]; // return to center view to give illusion of infinite scroll
    }
    
}

- (BOOL) didReachEdgeInDirection:(MealPageDirection)direction
{
    // gets mealInfo for meal in paging direction
    // then queries for list of meals for mealInfo to get accurate startTime
    // then performs another query to see if any meals exist that come before/after this startTime
    //   - assummes earliest meal in set will start before all other meals in day
    //          - will return incorrect value if there is a breakfast that starts after a brunch and we are paging left, query for meals before earliest brunch would fail
    
    MealReference *ref = [self mealReferenceForMealInDirection:direction];

    NSPredicate *dayPredicate;
    NSPredicate *mealPredicate;
    if (direction == kPageDirectionForward) {
        dayPredicate = [NSPredicate predicateWithFormat:@"date > %@", [ref.date endOfDay]];
        mealPredicate = [NSPredicate predicateWithFormat:@"name !=[c] %@ AND startTime > %@", ref.name, ref.date];
    } else {
        dayPredicate = [NSPredicate predicateWithFormat:@"date < %@", [ref.date startOfDay]];
        mealPredicate = [NSPredicate predicateWithFormat:@"name !=[c] %@ AND startTime < %@", ref.name, ref.date];
    }
    
    NSArray * days = [CoreDataManager objectsForEntity:@"DiningDay" matchingPredicate:dayPredicate];
    if ([days count]) {
        // we can stop here if there are DiningDays in direction. Definitely not at edge
        return NO;
    }
    
    // also need to check for meals in same day. otherwise won't let dinner page to breakfast on left edge and vice versa on right edge
    NSArray *meals = [CoreDataManager objectsForEntity:@"DiningMeal" matchingPredicate:mealPredicate];
    if ([meals count]) {
        return NO;
    }
    return YES;
}

# pragma mark - Paging
- (void) pagePointersRight
{
    // moves data reference to the right, reloads all views
    self.previousFRC = self.currentFRC;
    self.previous.mealRef = self.current.mealRef;
    
    self.currentFRC = self.nextFRC;
    self.current.mealRef = self.next.mealRef;
    self.mealRef = self.current.mealRef;
    
    MealReference *ref = [self mealReferenceForMealInDirection:kPageDirectionForward];
    self.nextFRC = [self fetchedResultsControllerForMealReference:ref];
    [self.nextFRC performFetch:nil];
    
    [self.current setScrollOffset:self.next.contentOffset animated:NO];
    [self.next resetScrollOffset];
    [self.previous setScrollOffsetAgainstRightEdge];
    self.next.mealRef = ref;

    [self reloadAllComparisonViews];
}

- (void) pagePointersLeft
{
    // moves data reference to the left, reloads all views
    self.nextFRC = self.currentFRC;
    self.next.mealRef = self.current.mealRef;
    
    self.currentFRC = self.previousFRC;
    self.current.mealRef = self.previous.mealRef;
    self.mealRef = self.current.mealRef;
    
    MealReference *ref = [self mealReferenceForMealInDirection:kPageDirectionBackward];
    self.previousFRC = [self fetchedResultsControllerForMealReference:ref];
    [self.previousFRC performFetch:nil];
    
    [self.current setScrollOffset:self.previous.contentOffset animated:NO];
    [self.previous setScrollOffsetAgainstRightEdge];
    [self.next resetScrollOffset];
    self.previous.mealRef = ref;

    [self reloadAllComparisonViews];
}

- (MealReference *) mealReferenceForMealInDirection:(MealPageDirection)direction
{
    // get meal information for meal before or after current Meal Reference
    
    NSString *newMealPointer = self.mealRef.name;
    NSDate * newDatePointer = self.mealRef.date;
    
    NSArray *queryResults = nil;
    
    while (![queryResults count] ) {
        // need to find next meal name that has meals available
        NSInteger pointerIndex = [MEAL_ORDER indexOfObject:newMealPointer];
        if ((pointerIndex + direction) >= [MEAL_ORDER count] || (pointerIndex + direction) < 0) {
            // newIndex is out of range, update day
            newDatePointer = (direction == kPageDirectionForward) ? [newDatePointer dayAfter] : [newDatePointer dayBefore];

            if (abs([newDatePointer timeIntervalSinceDate:self.mealRef.date]) >= (SECONDS_IN_DAY * 2)) {
                // Return a MealReference with a flag saying it is an empty meal reference. date is correct, but meal name is not valid
                newDatePointer = (direction == kPageDirectionForward) ? [self.mealRef.date dayAfter] : [self.mealRef.date dayBefore];
                return [MealReference referenceWithMealName:MealReferenceEmptyMeal onDate:newDatePointer];
                break;
            }
        }
        
        NSInteger nextMealIndex = (pointerIndex + direction) % [MEAL_ORDER count];
        newMealPointer = MEAL_ORDER[nextMealIndex];
        
        queryResults = [CoreDataManager objectsForEntity:@"DiningMeal" matchingPredicate:[NSPredicate predicateWithFormat:@"name ==[c] %@ AND startTime >= %@ AND startTime <= %@", newMealPointer, [newDatePointer startOfDay], [newDatePointer endOfDay]]];
    }
    
    return [MealReference referenceWithMealName:newMealPointer onDate:[[queryResults lastObject] startTime]];
}

- (NSString *) bestMealForDate:(NSDate *) date
{
    // used to get initial meal viewed
    
    NSString *mealEntity = @"DiningMeal";
    DiningMeal *meal = nil;
    NSSortDescriptor *startTimeAscending = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
    
    NSPredicate *inProgress = [NSPredicate predicateWithFormat:@"startTime <= %@ AND endTime >= %@", date, date];               // date is between a startTime and endTime
    NSArray *results = [CoreDataManager objectsForEntity:mealEntity matchingPredicate:inProgress sortDescriptors:@[startTimeAscending]];
    if ([results count]) {
        meal = results[0];
        return meal.name;
    }
    
    NSPredicate *isUpcoming = [NSPredicate predicateWithFormat:@"startTime > %@ AND startTime < %@", date, [date endOfDay]];    // meal starts after date but starts before the end of the date's day
    results = [CoreDataManager objectsForEntity:mealEntity matchingPredicate:isUpcoming sortDescriptors:@[startTimeAscending]];
    if ([results count]) {
        meal = results[0];
        return meal.name;
    }
    
    NSPredicate *lastOfDay = [NSPredicate predicateWithFormat:@"startTime >= %@ AND endTime <= %@", [date startOfDay], [date endOfDay]];    // all meals that occur in the day
    results = [CoreDataManager objectsForEntity:mealEntity matchingPredicate:lastOfDay sortDescriptors:@[startTimeAscending]];              // sorted by startTime
    meal = [results lastObject];                                                                                                            // grab last meal
    return meal.name;
}

- (MealReference *) visibleMealReference
{
    // Gets Meal reference of Comparison view currently on screen
    CGFloat xOffset = self.scrollView.contentOffset.x;
    if (xOffset >= CGRectGetMaxX(self.current.frame)) {
        // to the right of center
        NSLog(@"Viewing Next");
        return self.next.mealRef;
    } else if (xOffset >= CGRectGetMaxX(self.previous.frame)) {
        // to the right of left
        NSLog(@"Viewing Center");
        return self.current.mealRef;
    } else {
        // must be left
        NSLog(@"Viewing Previous");
        return self.previous.mealRef;
    }
}

#pragma mark - DiningCompareView Helper Methods
- (void) reloadAllComparisonViews
{
    [self.previous reloadData];
    [self.current reloadData];
    [self.next reloadData];
}

- (NSFetchedResultsController *) resultsControllerForCompareView:(DiningHallMenuCompareView *)compareView
{
    if (compareView == self.previous) {
        return self.previousFRC;
    } else if (compareView == self.current) {
        return self.currentFRC;
    } else if (compareView == self.next) {
        return self.nextFRC;
    }
    return nil;
}

- (NSInteger) indexOfSectionInController:(NSFetchedResultsController *)controller withCompareViewSection:(NSInteger)compareViewSection
{
    // need to convert compare view section (0 through 4) to whatever section controller contains (controllers never contain empty sections)
    NSString *sectionName = self.houseVenueSections[compareViewSection];
    NSArray *sections = [controller sections];
    NSArray *sectionTitles = [sections valueForKey:@"name"];
    return [sectionTitles indexOfObject:sectionName];
}

#pragma mark - DiningCompareViewDelegate
- (NSString *) titleForCompareView:(DiningHallMenuCompareView *)compareView
{
    MealReference *mRef;
    MealPageDirection direction = kPageDirectionNone;
    if (compareView == self.previous) {
        direction = kPageDirectionBackward;
        
    } else if (compareView == self.current) {
        return [DiningHallMenuCompareView stringForMeal:self.mealRef.name onDate:self.mealRef.date];
    } else if (compareView == self.next) {
        direction = kPageDirectionForward;
    }
    
    mRef = [self mealReferenceForMealInDirection:direction];
    return [DiningHallMenuCompareView stringForMeal:mRef.name onDate:mRef.date];
}

- (NSInteger) numberOfSectionsInCompareView:(DiningHallMenuCompareView *)compareView
{
    return 5;
}

- (NSString *) compareView:(DiningHallMenuCompareView *)compareView titleForSection:(NSInteger)section
{
    return self.houseVenueSections[section];
    
}

- (NSString *) compareView:(DiningHallMenuCompareView *)compareView subtitleForSection:(NSInteger)section
{
    DiningMeal *meal = [MealReference mealForReference:compareView.mealRef atVenueWithShortName:self.houseVenueSections[section]];
    if (!meal) {
        return @"";
    }
    
    [self.sectionSubtitleFormatter setDateFormat:@"h:mm"];
    NSString *start = [self.sectionSubtitleFormatter stringFromDate:meal.startTime];
    
    [self.sectionSubtitleFormatter setDateFormat:@"h:mm a"];
    NSString *end = [self.sectionSubtitleFormatter stringFromDate:meal.endTime];
    
    return [NSString stringWithFormat:@"%@ - %@", start, end];
}

- (NSInteger) compareView:(DiningHallMenuCompareView *)compareView numberOfItemsInSection:(NSInteger) section
{
    NSFetchedResultsController *controller = [self resultsControllerForCompareView:compareView];
    if (!controller) {
        return 0;
    }
    NSInteger cSectionIndex = [self indexOfSectionInController:controller withCompareViewSection:section];

    if (cSectionIndex == NSNotFound) {
        return 1;       // necessary to show section header
    }
    id<NSFetchedResultsSectionInfo> sectionInfo = [controller sections][cSectionIndex];
    if ([sectionInfo numberOfObjects]) {
        return [sectionInfo numberOfObjects];
    } else {
        return 1;       // necessary for 'No Meals' cell
    }
}

- (PSTCollectionViewCell *) compareView:(DiningHallMenuCompareView *)compareView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSFetchedResultsController *controller = [self resultsControllerForCompareView:compareView];
    NSInteger cSectionIndex = [self indexOfSectionInController:controller withCompareViewSection:indexPath.section];
    
    DiningMealItem *item = nil;
    if (cSectionIndex == NSNotFound) {
        item = nil;
    } else {
        id<NSFetchedResultsSectionInfo> sectionInfo = [controller sections][cSectionIndex];
        item = [sectionInfo objects][indexPath.row];
    }
    
    
    if (item) {
        DiningHallMenuComparisonCell *cell = [compareView dequeueReusableCellWithReuseIdentifier:@"DiningMenuCell" forIndexPath:indexPath];
        cell.primaryLabel.text = item.name;
        cell.primaryLabel.textAlignment = NSTextAlignmentLeft;
        cell.secondaryLabel.text = item.subtitle;
        cell.dietaryTypes = [item.dietaryFlags allObjects];
        return cell;
    } else {
        DiningHallMenuComparisonNoMealsCell *cell = [compareView dequeueReusableCellWithReuseIdentifier:@"DiningMenuNoMealsCell" forIndexPath:indexPath];
        DiningMeal *meal = [MealReference mealForReference:compareView.mealRef atVenueWithShortName:self.houseVenueSections[indexPath.section]];
        NSString *text;
        if (!meal) {
            text = @"closed";
        } else if ([meal.items count]) {
            text = @"no matching items";
        } else {
            text = @"no items";
        }
        cell.primaryLabel.text = text;
        
        return cell;
    }
}

- (CGFloat) compareView:(DiningHallMenuCompareView *)compareView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSFetchedResultsController *controller = [self resultsControllerForCompareView:compareView];
    NSInteger cSectionIndex = [self indexOfSectionInController:controller withCompareViewSection:indexPath.section];
    
    if (cSectionIndex == NSNotFound) {
        return 30;       // necessary to show section header
    }
    id<NSFetchedResultsSectionInfo> sectionInfo = [controller sections][cSectionIndex];
    DiningMealItem *item = [sectionInfo objects][indexPath.row];
    
    if (item) {
        return [DiningHallMenuComparisonCell heightForComparisonCellOfWidth:compareView.columnWidth withPrimaryText:item.name secondaryText:item.subtitle numDietaryTypes:[item.dietaryFlags count]];
    } else {
        return 30;
    }
}

- (void) compareViewDidEndDecelerating:(DiningHallMenuCompareView *)compareView
{
    if (self.pauseBeforeResettingScrollOffset) {
        if (self.previous == compareView) {
            [self pagePointersLeft];
        } else if (self.next == compareView) {
            [self pagePointersRight];
        }
        
        [self.scrollView setContentOffset:CGPointMake(self.current.frame.origin.x - DAY_VIEW_PADDING, 0) animated:NO]; // return to center view to give illusion of infinite scroll
        self.pauseBeforeResettingScrollOffset = NO;
    }
}



@end
