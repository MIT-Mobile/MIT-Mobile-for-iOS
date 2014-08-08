#import "MITEventsHomeViewControllerPad.h"
#import "MITCalendarSelectionViewController.h"
#import "MITCalendarPageViewController.h"
#import "MITDateNavigationBarView.h"
#import "MITEventsMapViewController.h"
#import "MITDatePickerViewController.h"
#import "MITCalendarManager.h"
#import "MITEventsSplitViewController.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "NSDate+MITAdditions.h"
#import "MITEventSearchTypeAheadViewController.h"
#import "MITEventSearchResultsViewController.h"
#import "MITAcademicHolidaysCalendarViewController.h"
#import "MITAcademicCalendarViewController.h"

typedef NS_ENUM(NSUInteger, MITEventDateStringStyle) {
    MITEventDateStringStyleFull,
    MITEventDateStringStyleShortenedMonth,
    MITEventDateStringStyleShortenedDay
};

static CGFloat const kMITEventHomeMasterWidthPortrait = 320.0;
static CGFloat const kMITEventHomeMasterWidthLandscape = 380.0;

@interface MITEventsHomeViewControllerPad () <MITDatePickerViewControllerDelegate, MITCalendarPageViewControllerDelegate, UISplitViewControllerDelegate, MITEventSearchTypeAheadViewControllerDelegate, MITEventSearchResultsViewControllerDelegate, UISearchBarDelegate, MITCalendarSelectionDelegate>

@property (strong, nonatomic) MITEventsSplitViewController *splitViewController;
@property (strong, nonatomic) MITEventsMapViewController *mapsViewController;

@property (nonatomic, strong) MITEventSearchTypeAheadViewController *typeAheadViewController;
@property (nonatomic, strong) UIPopoverController *typeAheadPopoverController;
@property (nonatomic, strong) MITEventSearchResultsViewController *resultsViewController;

@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIBarButtonItem *searchMagnifyingGlassBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *searchCancelBarButtonItem;

@property (strong, nonatomic) MITCalendarPageViewController *eventsPageViewController;
@property (strong, nonatomic) MITDateNavigationBarView *dateNavigationBarView;

@property (strong, nonatomic) UIPopoverController *currentPopoverController;

@property (nonatomic, strong) MITMasterCalendar *masterCalendar;
@property (nonatomic, strong) MITCalendarsCalendar *currentlySelectedCalendar;
@property (nonatomic, strong) MITCalendarsCalendar *currentlySelectedCategory;

@property (nonatomic, strong) UIPopoverController *calendarSelectorPopoverController;
@property (nonatomic, strong) MITCalendarSelectionViewController *calendarSelectionViewController;
@property (nonatomic, strong) UIBarButtonItem *calendarSelectionBarButtonItem;

@property (strong, nonatomic) NSDate *currentlyDisplayedDate;

@end

@implementation MITEventsHomeViewControllerPad

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"MIT Events";
    [self setupViewControllers];
    [self setupRightBarButtonItems];
    [self setupToolbar];
    
    [[MITCalendarManager sharedManager] getCalendarsCompletion:^(MITMasterCalendar *masterCalendar, NSError *error) {
        if (masterCalendar) {
            self.masterCalendar = masterCalendar;
            self.currentlySelectedCalendar = masterCalendar.eventsCalendar;
            [self loadEvents];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
    [self setupLeftBarButtonItems];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self alignDateNavigationBar];
    [self updateDateLabel];
}

- (void)alignDateNavigationBar
{
    UIView *customView = [[self.navigationItem.leftBarButtonItems lastObject] customView];
    CGRect currentRect = [self.view convertRect:customView.bounds fromView:customView];
    
    [self alignDateNavigationBarForOriginX:currentRect.origin.x];
}

- (void)alignDateNavigationBarForOriginX:(CGFloat)originX
{
    CGFloat targetWidth = kMITEventHomeMasterWidthPortrait;
    if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        targetWidth = kMITEventHomeMasterWidthLandscape;
    }
    
    self.dateNavigationBarView.bounds = CGRectMake(0, 0, targetWidth - originX, CGRectGetHeight(self.dateNavigationBarView.bounds));
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self alignDateNavigationBar];
    [self updateDateLabel];
}

#pragma mark - BarButtonItems Setup

- (void)setupLeftBarButtonItems
{
    if (!self.dateNavigationBarView) {
        [self setupDateNavigationBar];
        
        UIBarButtonItem *dateNavBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.dateNavigationBarView];
        NSMutableArray *currentItems = [NSMutableArray array];
        [currentItems addObject:self.navigationItem.leftBarButtonItems.firstObject];
        [currentItems addObject:dateNavBarButtonItem];
        self.navigationItem.leftBarButtonItems = currentItems;
    }
}

- (void)setupDateNavigationBar
{
    UINib *nib = [UINib nibWithNibName:@"MITDateNavigationBarView" bundle:nil];
    self.dateNavigationBarView = [[nib instantiateWithOwner:self options:nil] objectAtIndex:0];
    self.dateNavigationBarView.bounds = CGRectMake(0, 0, 320, 44);
    self.dateNavigationBarView.tintColor = [UIColor mit_tintColor];
    self.dateNavigationBarView.currentDateLabel.text = @"";
    [self setupDateNavigationButtonPresses];
    
    // We will calculate the absolute value programmatically as a fail safe, but since it's always 57, this helps initial setup to look cleaner
    CGFloat originOfSecondBarButtonItemX = 57.0;
    [self alignDateNavigationBarForOriginX:originOfSecondBarButtonItemX];
}

- (void)setupDateNavigationButtonPresses
{
    [self.dateNavigationBarView.previousDateButton addTarget:self action:@selector(previousDayButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.dateNavigationBarView.nextDateButton addTarget:self action:@selector(nextDayButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.dateNavigationBarView.showDateControlButton addTarget:self action:@selector(showDatePickerButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupRightBarButtonItems
{
    self.searchMagnifyingGlassBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"global/search"]
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(searchButtonPressed:)];
     self.navigationItem.rightBarButtonItem = self.searchMagnifyingGlassBarButtonItem;
}

- (void)showSearchBar
{
    if (!self.searchBar) {
        self.searchBar = [[UISearchBar alloc] init];
        self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
        self.searchBar.bounds = CGRectMake(0, 0, 260, 44);
        self.searchBar.showsCancelButton = YES;
        [self.searchBar setShowsCancelButton:YES animated:YES];
        self.searchBar.placeholder = @"Search";
        self.searchBar.delegate = self;
    }
    
    if (!self.searchCancelBarButtonItem) {
        self.searchCancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(searchButtonPressed:)];
    }
    
    UIBarButtonItem *searchBarAsBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.searchBar];
    self.navigationItem.rightBarButtonItems = @[self.searchCancelBarButtonItem, searchBarAsBarButtonItem];
    
    [self.searchBar becomeFirstResponder];
    
    self.typeAheadPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.typeAheadViewController];
    CGRect presentationRect = self.searchBar.frame;// [self.view convertRect:self.searchBar.frame fromView:self.searchBar];
    presentationRect.origin.y += presentationRect.size.height / 2;
    [self.typeAheadPopoverController presentPopoverFromRect:presentationRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)hideSearchBar
{
    self.splitViewController.viewControllers = @[self.eventsPageViewController, self.mapsViewController];
    
    if (!self.searchMagnifyingGlassBarButtonItem) {
        UIImage *searchImage = [UIImage imageNamed:@"global/search"];
        self.searchMagnifyingGlassBarButtonItem = [[UIBarButtonItem alloc] initWithImage:searchImage
                                                                                   style:UIBarButtonItemStylePlain
                                                                                  target:self
                                                                                  action:@selector(searchButtonPressed:)];
    }
    self.navigationItem.rightBarButtonItems = @[self.searchMagnifyingGlassBarButtonItem];
}

#pragma mark - Date Navigation Bar Button Presses

- (void)previousDayButtonPressed:(UIButton *)sender
{
    self.currentlyDisplayedDate = [self.eventsPageViewController.date dayBefore];
}

- (void)nextDayButtonPressed:(UIButton *)sender
{
    self.currentlyDisplayedDate = [self.eventsPageViewController.date dayAfter];
}

- (void)showDatePickerButtonPressed:(UIButton *)sender
{
    CGSize targetPopoverSize = CGSizeMake(320, 320);
    CGRect actualButtonRect = [self.view convertRect:sender.bounds fromView:sender];
    actualButtonRect.size.height -= 8; // small offset to bring pointer closer
    
    MITDatePickerViewController *datePickerViewController = [MITDatePickerViewController new];
    datePickerViewController.delegate = self;
    datePickerViewController.shouldHideCancelButton = YES;
    UINavigationController *datePickerNavController = [[UINavigationController alloc] initWithRootViewController:datePickerViewController];
    UIPopoverController *popOverController = [[UIPopoverController alloc] initWithContentViewController:datePickerNavController];
    [popOverController setPopoverContentSize:targetPopoverSize];
    [popOverController presentPopoverFromRect:actualButtonRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    self.currentPopoverController = popOverController;
}

#pragma mark - Search

- (void)searchButtonPressed:(UIBarButtonItem *)barButtonItem
{
    if (barButtonItem == self.searchMagnifyingGlassBarButtonItem) {
        [self showSearchBar];
    }
    else if (barButtonItem == self.searchCancelBarButtonItem) {
        [self hideSearchBar];
    }
}

- (void)beginSearch:(NSString *)searchString
{
    self.searchBar.text = searchString;
    [self.searchBar resignFirstResponder];
    [self.typeAheadPopoverController dismissPopoverAnimated:YES];
    self.splitViewController.viewControllers = @[self.resultsViewController, self.mapsViewController];
    [self.resultsViewController beginSearch:searchString];
}

#pragma mark - UISearchBarDelegate Methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self beginSearch:searchBar.text];
}

#pragma mark - ViewControllers Setup

- (void)setupViewControllers
{
    [self setupEventsPageViewController];
    [self setupMapViewController];
    [self setupSplitViewController];
    [self setupTypeAheadViewController];
    [self setupResultsViewController];
}

- (void)setupEventsPageViewController
{
    self.eventsPageViewController = [[MITCalendarPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                             navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                           options:nil];
    self.eventsPageViewController.calendarSelectionDelegate = self;
}

- (void)loadEvents
{
    self.eventsPageViewController.calendar = self.currentlySelectedCalendar;
    self.eventsPageViewController.category = self.currentlySelectedCategory;
    self.currentlyDisplayedDate = [[NSDate date] beginningOfDay];
}

- (void)setupMapViewController
{
    self.mapsViewController = [MITEventsMapViewController new];
    self.mapsViewController.view.backgroundColor = [UIColor magentaColor];
}

- (void)setupSplitViewController
{
    self.splitViewController = [[MITEventsSplitViewController alloc] init];
    self.splitViewController.viewControllers = @[self.eventsPageViewController, self.mapsViewController];
    self.splitViewController.delegate = self;
    
    [self addChildViewController:self.splitViewController];
    self.splitViewController.view.frame = self.view.bounds;
    [self.view addSubview:self.splitViewController.view];
    [self.splitViewController didMoveToParentViewController:self];
}

- (void)setupTypeAheadViewController
{
    self.typeAheadViewController = [[MITEventSearchTypeAheadViewController alloc] initWithNibName:nil bundle:nil];
    self.typeAheadViewController.delegate = self;
    self.typeAheadViewController.currentCalendar = self.currentlySelectedCategory;
}

- (void)setupResultsViewController
{
    self.resultsViewController = [[MITEventSearchResultsViewController alloc] initWithNibName:nil bundle:nil];
    self.resultsViewController.delegate = self;
    self.resultsViewController.currentCalendar = self.currentlySelectedCategory;
}

#pragma mark - ToolBar Setup

- (void)setupToolbar
{
    [self setToolbarItems:@[[self leftToolbarItem], [self flexibleSpaceBarButtonItem], [self middleToolbarItem], [self flexibleSpaceBarButtonItem], [self rightToolbarItem]]];
}

- (UIBarButtonItem *)leftToolbarItem
{
    return [[UIBarButtonItem alloc] initWithTitle:@"Today"
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(todayButtonPressed:)];
}

- (UIBarButtonItem *)middleToolbarItem
{
    if (!self.calendarSelectionBarButtonItem) {
        self.calendarSelectionBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Calendars"
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(calendarsButtonPressed:)];
    }
    
    return self.calendarSelectionBarButtonItem;
}

- (UIBarButtonItem *)rightToolbarItem
{
    UIImage *locationImage = [UIImage imageNamed:@"global/location"];
    return [[UIBarButtonItem alloc] initWithImage:locationImage
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(currentLocationButtonPressed:)];
}

- (UIBarButtonItem *)flexibleSpaceBarButtonItem
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                         target:nil
                                                         action:nil];
}

#pragma mark - Calendar Selection

- (MITCalendarSelectionViewController *)calendarSelectionViewController
{
    if (!_calendarSelectionViewController)
    {
        _calendarSelectionViewController = [[MITCalendarSelectionViewController alloc] initWithStyle:UITableViewStyleGrouped];
        _calendarSelectionViewController.delegate = self;
    }
    return _calendarSelectionViewController;
}

- (void)calendarSelectionViewController:(MITCalendarSelectionViewController *)viewController
                      didSelectCalendar:(MITCalendarsCalendar *)calendar
                               category:(MITCalendarsCalendar *)category
{
    if (calendar) {
        self.currentlySelectedCalendar = calendar;
        self.currentlySelectedCategory = category;
        self.typeAheadViewController.currentCalendar = self.currentlySelectedCategory;
        self.resultsViewController.currentCalendar = self.currentlySelectedCategory;
        
        if ([calendar.identifier isEqualToString:[MITCalendarManager sharedManager].masterCalendar.academicHolidaysCalendar.identifier]) {
            MITAcademicHolidaysCalendarViewController *holidaysVC = [[MITAcademicHolidaysCalendarViewController alloc] init];
            self.splitViewController.viewControllers = @[holidaysVC, self.mapsViewController];
        } else if ([calendar.identifier isEqualToString:[MITCalendarManager sharedManager].masterCalendar.academicCalendar.identifier]) {
            MITAcademicCalendarViewController *academicVC = [[MITAcademicCalendarViewController alloc] init];
            self.splitViewController.viewControllers = @[academicVC, self.mapsViewController];
        } else {
            self.splitViewController.viewControllers = @[self.eventsPageViewController, self.mapsViewController];
            [self.eventsPageViewController moveToCalendar:self.currentlySelectedCalendar
                                                 category:self.currentlySelectedCategory
                                                     date:self.currentlyDisplayedDate
                                                 animated:YES];
        }
    }
    
    [self.calendarSelectorPopoverController dismissPopoverAnimated:YES];
}

#pragma mark - Toolbar Button Presses

- (void)todayButtonPressed:(id)sender
{
    NSDate *today = [[NSDate date] beginningOfDay];
    self.currentlyDisplayedDate = today;
}

- (void)calendarsButtonPressed:(id)sender
{
    UINavigationController *navContainerController = [[UINavigationController alloc] initWithRootViewController:self.calendarSelectionViewController];
    self.calendarSelectorPopoverController = [[UIPopoverController alloc] initWithContentViewController:navContainerController];
    [self.calendarSelectorPopoverController presentPopoverFromBarButtonItem:self.calendarSelectionBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

- (void)currentLocationButtonPressed:(id)sender
{
    [self.mapsViewController showCurrentLocation];
}

#pragma mark - MITDatePickerControllerDelegate

- (void)datePicker:(MITDatePickerViewController *)datePicker didSelectDate:(NSDate *)date
{
    [self.currentPopoverController dismissPopoverAnimated:YES];
    self.currentlyDisplayedDate = date;
}

- (void)datePickerDidCancel:(MITDatePickerViewController *)datePicker
{
    // No cancel button visible
}

#pragma mark - MITCalendarPageViewControllerDelegate

- (void)calendarPageViewController:(MITCalendarPageViewController *)viewController
                    didSwipeToDate:(NSDate *)date
{
    // Don't use setter here to avoid trying to move to date that
    _currentlyDisplayedDate = date;
    [self updateDateLabel];
}
- (void)calendarPageViewController:(MITCalendarPageViewController *)viewController
                    didSelectEvent:(MITCalendarsEvent *)event
{
    
}

- (void)calendarPageViewController:(MITCalendarPageViewController *)viewController
 didUpdateCurrentlyDisplayedEvents:(NSArray *)currentlyDisplayedEvents
{
    [self.mapsViewController updateMapWithEvents:currentlyDisplayedEvents];
}

#pragma mark - Date Bar

- (void)updateDateLabel
{
    NSUInteger currentDateStyle = MITEventDateStringStyleFull;
    CGFloat targetWidth = MAXFLOAT;
    CGFloat maxWidth = CGRectGetWidth(self.dateNavigationBarView.currentDateLabel.bounds);
    NSString *dateString = nil;
    NSUInteger totalNumberOfDateStyles = 3;
    while (targetWidth > maxWidth && currentDateStyle < totalNumberOfDateStyles) {
        dateString = [self dateStringForDate:self.currentlyDisplayedDate withStyle:currentDateStyle];
        CGSize targetSize = [dateString sizeWithFont:self.dateNavigationBarView.currentDateLabel.font];
        targetWidth = targetSize.width;
        currentDateStyle++;
    }
    self.dateNavigationBarView.currentDateLabel.text = dateString;
}

- (NSString *)dateStringForDate:(NSDate *)date withStyle:(MITEventDateStringStyle)dateStringStyle
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale currentLocale];
    switch (dateStringStyle) {
        case MITEventDateStringStyleFull:
            dateFormatter.dateStyle = NSDateFormatterFullStyle;
            break;
        case MITEventDateStringStyleShortenedMonth:
            dateFormatter.dateFormat = @"EEEE, MMM d, y";
            break;
        case MITEventDateStringStyleShortenedDay:
            dateFormatter.dateFormat = @"EEE, MMM d, y";
            break;
        default:
            break;
    }
    return [dateFormatter stringFromDate:date];
}

#pragma mark - UISplitViewControllerDelegate

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    return NO;  // show both view controllers in all orientations
}

#pragma mark - MITEventSearchTypeAheadViewControllerDelegate Methods

- (void)eventSearchTypeAheadController:(MITEventSearchTypeAheadViewController *)typeAheadController didSelectSuggestion:(NSString *)suggestion
{
    [self beginSearch:suggestion];
}

#pragma mark - MITEventSearchResultsViewControllerDelegate Methods

- (void)eventSearchResultsViewController:(MITEventSearchResultsViewController *)resultsViewController didSelectEvent:(MITCalendarsEvent *)event
{
//    MITEventDetailViewController *detailVC = [[MITEventDetailViewController alloc] initWithNibName:nil bundle:nil];
//    detailVC.event = event;
//    [self.navigationController pushViewController:detailVC animated:YES];
}

#pragma mark - Getters | Setters

- (void)setCurrentlyDisplayedDate:(NSDate *)currentlyDisplayedDate
{
    _currentlyDisplayedDate = currentlyDisplayedDate;
    [self updateDateLabel];
    [self.eventsPageViewController moveToCalendar:self.currentlySelectedCalendar category:self.currentlySelectedCategory date:currentlyDisplayedDate animated:YES];
}

@end
