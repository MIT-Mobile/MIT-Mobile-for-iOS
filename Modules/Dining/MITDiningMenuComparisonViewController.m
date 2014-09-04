#import "MITDiningMenuComparisonViewController.h"
#import "MITDiningHallMenuComparisonView.h"
#import "CoreDataManager.h"
#import "Foundation+MITAdditions.h"

#import "MITAdditions.h"

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



@interface MITDiningMenuComparisonViewController () <UIScrollViewDelegate, DiningCompareViewDelegate>

@property (nonatomic,weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic,weak) IBOutlet NSLayoutConstraint *topSpacingConstraint;

@property (nonatomic,strong) MealReference *visibleMealReference;

@property (nonatomic,weak) MITDiningHallMenuComparisonView * previous;     // on left
@property (nonatomic,weak) MITDiningHallMenuComparisonView * current;      // center
@property (nonatomic,weak) MITDiningHallMenuComparisonView * next;         // on right

@property (nonatomic, strong) NSArray * houseVenueSections;     // array of houseVenueSection titles, needed because fetchedResultsController will not return empty sections

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *previousFRC;
@property (nonatomic, strong) NSFetchedResultsController *currentFRC;
@property (nonatomic, strong) NSFetchedResultsController *nextFRC;

@property (nonatomic, assign) BOOL pauseBeforeResettingScrollOffset;
@end

@implementation MITDiningMenuComparisonViewController

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

    self.view.backgroundColor = [UIColor mit_backgroundColor];
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = [UIColor clearColor];
    
    MITDiningHallMenuComparisonView *previous = [[MITDiningHallMenuComparisonView alloc] init];
    previous.delegate = self;
    [self.scrollView addSubview:previous];
    self.previous = previous;
    
    MITDiningHallMenuComparisonView *current = [[MITDiningHallMenuComparisonView alloc] init];
    current.delegate = self;
    [self.scrollView addSubview:current];
    self.current = current;
    
    MITDiningHallMenuComparisonView *next = [[MITDiningHallMenuComparisonView alloc] init];
    next.delegate = self;
    [self.scrollView addSubview:next];
    self.next = next;
    
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
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
    
    self.visibleMealReference = self.mealRef;
    
    if ([self didReachEdgeInDirection:kPageDirectionBackward]) {
        // Set the 'current'  meal reference (in this case, middle of the current page)
        // to the next meal..
        self.mealRef = [self mealReferenceForMealInDirection:kPageDirectionForward];
        
        //...and move the pointers around so everything is happy
        [self pagePointersRight];
    } else if ([self didReachEdgeInDirection:kPageDirectionForward]) { // Same as the above, only in the opposite direction
        self.mealRef = [self mealReferenceForMealInDirection:kPageDirectionBackward];
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
    [self scrollMealReferenceToVisible:self.visibleMealReference animated:animated];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGSize contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds) * 3 , CGRectGetHeight(self.scrollView.bounds));
    self.scrollView.contentSize = contentSize;

    // (viewPadding * 2) is used because each view has own padding, so there are 2 padded spaces to account for
    CGSize comparisonSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds) - (DAY_VIEW_PADDING * 2), CGRectGetHeight(self.scrollView.bounds));
    
    self.previous.frame = CGRectMake(DAY_VIEW_PADDING, 0, comparisonSize.width, comparisonSize.height);
    self.current.frame = CGRectMake(CGRectGetMaxX(self.previous.frame) + (DAY_VIEW_PADDING * 2), 0, comparisonSize.width, comparisonSize.height);
    self.next.frame = CGRectMake(CGRectGetMaxX(self.current.frame) + (DAY_VIEW_PADDING * 2), 0, comparisonSize.width, comparisonSize.height);
}

#pragma mark - Rotation
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self scrollMealReferenceToVisible:self.visibleMealReference animated:YES];
}

// Returns 'NO' if the reference is not on the current 'page'
- (BOOL)scrollMealReferenceToVisible:(MealReference*)reference animated:(BOOL)animated
{
    __block NSUInteger index = NSNotFound;
    NSArray *views = @[self.previous,self.current,self.next];
    
    if (reference || self.visibleMealReference) {
        if (!reference) {
            reference = self.visibleMealReference;
        }
    
        [views enumerateObjectsUsingBlock:^(MITDiningHallMenuComparisonView *menuView, NSUInteger idx, BOOL *stop) {
            if ([menuView.mealRef isEqual:reference]) {
                (*stop) = YES;
                index = idx;
            }
        }];
        
        if (index != NSNotFound) {
            MITDiningHallMenuComparisonView *menuView = views[index];
            
            CGPoint targetPoint = CGRectInset(menuView.frame, -DAY_VIEW_PADDING, 0.).origin;
            
            [self.scrollView setContentOffset:targetPoint animated:animated];
            
            if (index && (index < [views count])) {
                MITDiningHallMenuComparisonView *previousView = views[index - 1];
                [previousView setScrollOffsetAgainstRightEdge];
            }
        }
    }
    
    return (index != NSNotFound);
}

#pragma mark - Model methods
- (void)configureControllerWithMealReference:(MealReference*)mealReference
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"shortName" ascending:YES];
    NSArray *houseVenues = [CoreDataManager objectsForEntity:@"HouseVenue" matchingPredicate:nil sortDescriptors:@[sort]];
    self.houseVenueSections = [houseVenues valueForKey:@"shortName"];
    
    
}

- (void) loadData
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"shortName" ascending:YES];
    NSArray *houseVenues = [CoreDataManager objectsForEntity:@"HouseVenue" matchingPredicate:nil sortDescriptors:@[sort]];
    self.houseVenueSections = [houseVenues valueForKey:@"shortName"];
    
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
    MITDiningHallMenuComparisonView *viewToRecenter = self.current;
    
    // Handle infinite scroll between 3 views. Returns to center view so there is always a view on the left and right
    if (scrollView.contentOffset.x > scrollView.bounds.size.width) {
        // have scrolled to the right
        if ([self didReachEdgeInDirection:kPageDirectionForward]) {
            shouldCenter = YES;
            viewToRecenter = self.next;
        } else {
            if (!self.next.isScrolling) {
                [self pagePointersRight];
            } else {
                shouldCenter = NO;
                self.pauseBeforeResettingScrollOffset = YES;    // need to wait to reset scroll offset to center DiningComparisonView until comparisonview stops scrolling. only an issue when fast scrolling happens (page, scroll) IPHONEAPP-663
            }
        }
        
    } else if (scrollView.contentOffset.x < scrollView.bounds.size.width) {
        // have scrolled to the left
        if ([self didReachEdgeInDirection:kPageDirectionBackward]) {
            shouldCenter = YES;
            viewToRecenter = self.previous;
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
        CGRect contentFrame = CGRectInset(viewToRecenter.frame, -DAY_VIEW_PADDING, 0);
        [scrollView setContentOffset:contentFrame.origin animated:NO]; // return to center view to give illusion of infinite scroll
        self.visibleMealReference = viewToRecenter.mealRef;
        
        DDLogVerbose(@"Centered on meal reference '%@'",viewToRecenter.mealRef);
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
                //break;
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

#pragma mark - DiningCompareView Helper Methods
- (void) reloadAllComparisonViews
{
    [self.previous reloadData];
    [self.current reloadData];
    [self.next reloadData];
}

- (NSFetchedResultsController *) resultsControllerForCompareView:(MITDiningHallMenuComparisonView *)compareView
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
- (NSString *) titleForCompareView:(MITDiningHallMenuComparisonView *)compareView
{
    MealReference *mRef;
    MealPageDirection direction = kPageDirectionNone;
    if (compareView == self.previous) {
        direction = kPageDirectionBackward;
        
    } else if (compareView == self.current) {
        return [MITDiningHallMenuComparisonView stringForMeal:self.mealRef.name onDate:self.mealRef.date];
    } else if (compareView == self.next) {
        direction = kPageDirectionForward;
    }
    
    mRef = [self mealReferenceForMealInDirection:direction];
    return [MITDiningHallMenuComparisonView stringForMeal:mRef.name onDate:mRef.date];
}

- (NSInteger) numberOfSectionsInCompareView:(MITDiningHallMenuComparisonView *)compareView
{
#warning potentially unsafe hardcoded value
    return 5;
}

- (NSString *) compareView:(MITDiningHallMenuComparisonView *)compareView titleForSection:(NSInteger)section
{
    return self.houseVenueSections[section];
}

- (NSString *) compareView:(MITDiningHallMenuComparisonView *)compareView subtitleForSection:(NSInteger)section
{
    DiningMeal *meal = [MealReference mealForReference:compareView.mealRef atVenueWithShortName:self.houseVenueSections[section]];
    if (!meal) {
        return @"";
    }
    
    NSString *start = [[meal.startTime MITShortTimeOfDayString] lowercaseString];
    NSString *end = [[meal.endTime MITShortTimeOfDayString] lowercaseString];
    return [NSString stringWithFormat:@"%@ - %@", start, end];
}

- (NSInteger) compareView:(MITDiningHallMenuComparisonView *)compareView numberOfItemsInSection:(NSInteger) section
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

- (UICollectionViewCell *) compareView:(MITDiningHallMenuComparisonView *)compareView cellForRowAtIndexPath:(NSIndexPath *)indexPath
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
        MITDiningHallMenuComparisonCell *cell = [compareView dequeueReusableCellWithReuseIdentifier:@"DiningMenuCell" forIndexPath:indexPath];
        cell.primaryLabel.text = item.name;
        cell.primaryLabel.textAlignment = NSTextAlignmentLeft;
        cell.secondaryLabel.text = item.subtitle;
        cell.dietaryTypes = [item.dietaryFlags allObjects];
        return cell;
    } else {
        MITDiningHallMenuComparisonNoMealsCell *cell = [compareView dequeueReusableCellWithReuseIdentifier:@"DiningMenuNoMealsCell" forIndexPath:indexPath];
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

- (CGFloat) compareView:(MITDiningHallMenuComparisonView *)compareView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSFetchedResultsController *controller = [self resultsControllerForCompareView:compareView];
    NSInteger cSectionIndex = [self indexOfSectionInController:controller withCompareViewSection:indexPath.section];
    
    if (cSectionIndex == NSNotFound) {
        return 30;       // necessary to show section header
    }
    id<NSFetchedResultsSectionInfo> sectionInfo = [controller sections][cSectionIndex];
    DiningMealItem *item = [sectionInfo objects][indexPath.row];
    
    if (item) {
        return [MITDiningHallMenuComparisonCell heightForComparisonCellOfWidth:compareView.columnWidth withPrimaryText:item.name secondaryText:item.subtitle numDietaryTypes:[item.dietaryFlags count]];
    } else {
        return 30;
    }
}

- (void) compareViewDidEndDecelerating:(MITDiningHallMenuComparisonView *)compareView
{
    if (self.pauseBeforeResettingScrollOffset) {
        if (self.previous == compareView) {
            [self pagePointersLeft];
        } else if (self.next == compareView) {
            [self pagePointersRight];
        }

        [self.scrollView setContentOffset:CGPointMake(CGRectGetMinX(self.current.frame) - DAY_VIEW_PADDING, 0) animated:NO]; // return to center view to give illusion of infinite scroll
        self.pauseBeforeResettingScrollOffset = NO;
    }
}



@end
