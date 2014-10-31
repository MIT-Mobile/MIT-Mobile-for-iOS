#import "MITEventsHomeViewControllerPad.h"
#import "MITCalendarSelectionViewController.h"
#import "MITCalendarPageViewController.h"
#import "MITEventsMapViewController.h"
#import "MITDatePickerViewController.h"
#import "MITCalendarManager.h"
#import "MITEventsSplitViewController.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "MITEventSearchTypeAheadViewController.h"
#import "MITEventSearchResultsViewController.h"
#import "MITAcademicHolidaysCalendarViewController.h"
#import "MITAcademicCalendarViewController.h"
#import "MITEventDetailViewController.h"
#import "MITEventsTableViewController.h"
#import "MITExtendedNavBarView.h"
#import "UINavigationBar+ExtensionPrep.h"
#import "MITDayOfTheWeekCell.h"

#import "MITDayPickerViewController.h"

typedef NS_ENUM(NSUInteger, MITEventDateStringStyle) {
    MITEventDateStringStyleFull,
    MITEventDateStringStyleShortenedMonth,
    MITEventDateStringStyleShortenedDay
};

static CGFloat const kMITEventHomeNavBarExtensionHeight = 40.0;
static NSString * const kMITEventHomeDayPickerCollectionViewCellIdentifier = @"kMITEventHomeDayPickerCollectionViewCellIdentifier";

@interface MITEventsHomeViewControllerPad () <MITDatePickerViewControllerDelegate, MITCalendarPageViewControllerDelegate, UISplitViewControllerDelegate, MITEventSearchTypeAheadViewControllerDelegate, MITEventSearchResultsViewControllerDelegate, UISearchBarDelegate, MITCalendarSelectionDelegate, UIPopoverControllerDelegate, MITDayPickerViewControllerDelegate>

@property (strong, nonatomic) MITEventsSplitViewController *splitViewController;
@property (strong, nonatomic) MITEventDetailViewController *eventDetailViewController;

@property (nonatomic, strong) MITEventSearchTypeAheadViewController *typeAheadViewController;
@property (nonatomic, strong) UIPopoverController *typeAheadPopoverController;
@property (nonatomic, strong) MITEventSearchResultsViewController *resultsViewController;

@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIBarButtonItem *searchMagnifyingGlassBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *searchCancelBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *goToDateBarButtonItem;

@property (strong, nonatomic) MITCalendarPageViewController *eventsPageViewController;

@property (strong, nonatomic) UIPopoverController *currentPopoverController;

@property (nonatomic, strong) MITMasterCalendar *masterCalendar;
@property (nonatomic, strong) MITCalendarsCalendar *currentlySelectedCalendar;
@property (nonatomic, strong) MITCalendarsCalendar *currentlySelectedCategory;

@property (nonatomic, strong) UIPopoverController *calendarSelectorPopoverController;
@property (nonatomic, strong) MITCalendarSelectionViewController *calendarSelectionViewController;
@property (nonatomic, strong) UIBarButtonItem *calendarSelectionBarButtonItem;

@property (strong, nonatomic) MITExtendedNavBarView *extendedNavBarView;
@property (strong, nonatomic) MITDayPickerViewController *dayPickerController;
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
    [self setupExtendedNavBar];
    [self setupDayPickerController];
    
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
    [self alignExtendedNavBarAndDayPickerCollectionView];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self alignExtendedNavBarAndDayPickerCollectionView];
}

#pragma mark - BarButtonItems Setup

- (void)setupRightBarButtonItems
{
    self.searchMagnifyingGlassBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:MITImageBarButtonSearch]
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(searchButtonPressed:)];

    self.goToDateBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"calendar/day_picker_button"] style:UIBarButtonItemStylePlain target:self action:@selector(goToDateButtonPressed)];
    self.navigationItem.rightBarButtonItems = @[self.searchMagnifyingGlassBarButtonItem, self.goToDateBarButtonItem];
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

    [self showSearchPopover];
}

- (void)hideSearchBar
{
    self.splitViewController.viewControllers = @[self.eventsPageViewController, self.eventDetailViewController];

    if (!self.searchMagnifyingGlassBarButtonItem) {
        UIImage *searchImage = [UIImage imageNamed:MITImageBarButtonSearch];
        self.searchMagnifyingGlassBarButtonItem = [[UIBarButtonItem alloc] initWithImage:searchImage
                                                                                   style:UIBarButtonItemStylePlain
                                                                                  target:self
                                                                                  action:@selector(searchButtonPressed:)];
    }

    self.searchBar.text = @"";

    self.navigationItem.rightBarButtonItems = @[self.searchMagnifyingGlassBarButtonItem, self.goToDateBarButtonItem];

    MITEventsTableViewController *currentlyDisplayedController = (MITEventsTableViewController *)self.eventsPageViewController.viewControllers[0];
    if (currentlyDisplayedController.events.count > 0) {
        self.eventDetailViewController.event = currentlyDisplayedController.events[0];
    } else {
        self.eventDetailViewController.event = nil;
    }
}

- (void)showSearchPopover
{
    self.typeAheadPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.typeAheadViewController];
    self.typeAheadPopoverController.delegate = self;
    CGRect presentationRect = self.searchBar.frame;
    presentationRect.origin.y += presentationRect.size.height / 2;
    [self.typeAheadPopoverController presentPopoverFromRect:presentationRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];

    [self.searchBar becomeFirstResponder];
}

#pragma mark - Navigation Bar Extension

- (void)setupExtendedNavBar
{
    // TODO: Move to category
    UIColor *navbarGrey = [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0];

    self.extendedNavBarView = [MITExtendedNavBarView new];
    self.extendedNavBarView.backgroundColor = navbarGrey;
    [self.view addSubview:self.extendedNavBarView];
    [self.navigationController.navigationBar prepareForExtensionWithBackgroundColor:navbarGrey];
    [self alignExtendedNavBarAndDayPickerCollectionView];
}

- (void)alignExtendedNavBarAndDayPickerCollectionView
{
    self.extendedNavBarView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), kMITEventHomeNavBarExtensionHeight);
    self.dayPickerController.view.frame = self.extendedNavBarView.bounds;
}

#pragma mark - Date Navigation Bar Button Presses

- (void)showDatePickerButtonPressed:(UIButton *)sender
{
    CGSize targetPopoverSize = CGSizeMake(320, 320);

    MITDatePickerViewController *datePickerViewController = [MITDatePickerViewController new];
    datePickerViewController.delegate = self;
    datePickerViewController.shouldHideCancelButton = YES;
    UINavigationController *datePickerNavController = [[UINavigationController alloc] initWithRootViewController:datePickerViewController];
    UIPopoverController *popOverController = [[UIPopoverController alloc] initWithContentViewController:datePickerNavController];
    [popOverController setPopoverContentSize:targetPopoverSize];
    [popOverController presentPopoverFromBarButtonItem:self.goToDateBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
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
    self.splitViewController.viewControllers = @[self.resultsViewController, self.eventDetailViewController];
    [self.resultsViewController beginSearch:searchString];
}

#pragma mark - UISearchBarDelegate Methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self beginSearch:searchBar.text];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    if (!self.typeAheadPopoverController.isPopoverVisible) {
        [self showSearchPopover];
    }
}

#pragma mark - ViewControllers Setup

- (void)setupViewControllers
{
    [self setupEventsPageViewController];
    [self setupEventDetailViewController];
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
    self.dayPickerController.currentlyDisplayedDate = [[NSDate date] startOfDay];
}

- (void)setupEventDetailViewController
{
    self.eventDetailViewController = [[MITEventDetailViewController alloc] initWithNibName:nil bundle:nil];
}

- (void)setupSplitViewController
{
    self.splitViewController = [[MITEventsSplitViewController alloc] init];
    self.splitViewController.viewControllers = @[self.eventsPageViewController, self.eventDetailViewController];
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
    [self setToolbarItems:@[[self todayToolbarItem], [self flexibleSpaceBarButtonItem], [self calendarsToolbarItem]]];
}

- (UIBarButtonItem *)todayToolbarItem
{
    return [[UIBarButtonItem alloc] initWithTitle:@"Today"
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(todayButtonPressed:)];
}

- (UIBarButtonItem *)calendarsToolbarItem
{
    if (!self.calendarSelectionBarButtonItem) {
        self.calendarSelectionBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Calendars"
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(calendarsButtonPressed:)];
    }

    return self.calendarSelectionBarButtonItem;
}

- (UIBarButtonItem *)flexibleSpaceBarButtonItem
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                         target:nil
                                                         action:nil];
}

#pragma mark - DayPickerCollectionView Setup

- (void)setupDayPickerController
{
    self.dayPickerController = [MITDayPickerViewController new];
    self.dayPickerController.currentlyDisplayedDate = [[NSDate date] startOfDay];
    self.dayPickerController.delegate = self;
    self.dayPickerController.view.frame = self.extendedNavBarView.bounds;

    [self.dayPickerController willMoveToParentViewController:self];
    [self.extendedNavBarView addSubview:self.dayPickerController.view];
    [self addChildViewController:self.dayPickerController];
    [self.dayPickerController didMoveToParentViewController:self];
}

#pragma mark - MITDayPickerViewControllerDelegate

- (void)dayPickerViewController:(MITDayPickerViewController *)dayPickerViewController dateDidUpdate:(NSDate *)date
{
    if (![self.eventsPageViewController.date isEqualToDateIgnoringTime:date]) {
        [self.eventsPageViewController moveToCalendar:self.currentlySelectedCalendar category:self.currentlySelectedCategory date:date animated:YES];
    }
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
        self.title = category.name ? : calendar.name;
        self.currentlySelectedCalendar = calendar;
        self.currentlySelectedCategory = category;
        self.typeAheadViewController.currentCalendar = self.currentlySelectedCategory;
        self.resultsViewController.currentCalendar = self.currentlySelectedCategory;

        if ([calendar.identifier isEqualToString:[MITCalendarManager sharedManager].masterCalendar.academicHolidaysCalendar.identifier]) {
            MITAcademicHolidaysCalendarViewController *holidaysVC = [[MITAcademicHolidaysCalendarViewController alloc] init];
            self.splitViewController.viewControllers = @[holidaysVC, self.eventDetailViewController];
        } else if ([calendar.identifier isEqualToString:[MITCalendarManager sharedManager].masterCalendar.academicCalendar.identifier]) {
            MITAcademicCalendarViewController *academicVC = [[MITAcademicCalendarViewController alloc] init];
            self.splitViewController.viewControllers = @[academicVC, self.eventDetailViewController];
        } else {
            self.splitViewController.viewControllers = @[self.eventsPageViewController, self.eventDetailViewController];
            [self.eventsPageViewController moveToCalendar:self.currentlySelectedCalendar
                                                 category:self.currentlySelectedCategory
                                                     date:self.dayPickerController.currentlyDisplayedDate
                                                 animated:YES];
        }
    }

    [self.calendarSelectorPopoverController dismissPopoverAnimated:YES];
}

#pragma mark - Toolbar Button Presses

- (void)todayButtonPressed:(id)sender
{
    NSDate *today = [[NSDate date] startOfDay];
    self.dayPickerController.currentlyDisplayedDate = today;
}

- (void)calendarsButtonPressed:(id)sender
{
    UINavigationController *navContainerController = [[UINavigationController alloc] initWithRootViewController:self.calendarSelectionViewController];
    self.calendarSelectorPopoverController = [[UIPopoverController alloc] initWithContentViewController:navContainerController];
    [self.calendarSelectorPopoverController presentPopoverFromBarButtonItem:self.calendarSelectionBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

#pragma mark - MITDatePickerControllerDelegate

- (void)datePicker:(MITDatePickerViewController *)datePicker didSelectDate:(NSDate *)date
{
    [self.currentPopoverController dismissPopoverAnimated:YES];
    self.dayPickerController.currentlyDisplayedDate = date;
}

- (void)datePickerDidCancel:(MITDatePickerViewController *)datePicker
{
    // No cancel button visible
}

#pragma mark - MITCalendarPageViewControllerDelegate

- (void)calendarPageViewController:(MITCalendarPageViewController *)viewController
                    didSwipeToDate:(NSDate *)date
{
    self.dayPickerController.currentlyDisplayedDate = date;
}

- (void)calendarPageViewController:(MITCalendarPageViewController *)viewController
                    didSelectEvent:(MITCalendarsEvent *)event
{
    self.eventDetailViewController.event = event;
}

- (void)calendarPageViewController:(MITCalendarPageViewController *)viewController
 didUpdateCurrentlyDisplayedEvents:(NSArray *)currentlyDisplayedEvents
{
    if (currentlyDisplayedEvents.count > 0) {
        self.eventDetailViewController.event = currentlyDisplayedEvents[0];
    } else {
        self.eventDetailViewController.event = nil;
    }
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

- (void)eventSearchTypeAheadControllerDidClearFilters:(MITEventSearchTypeAheadViewController *)typeAheadController
{
    self.resultsViewController.currentCalendar = nil;
}

#pragma mark - MITEventSearchResultsViewControllerDelegate Methods

- (void)eventSearchResultsViewController:(MITEventSearchResultsViewController *)resultsViewController didLoadResults:(NSArray *)results
{
    if (results.count > 0) {
        self.eventDetailViewController.event = results[0];
    } else {
        self.eventDetailViewController.event = nil;
    }
}

- (void)eventSearchResultsViewController:(MITEventSearchResultsViewController *)resultsViewController didSelectEvent:(MITCalendarsEvent *)event
{
    self.eventDetailViewController.event = event;
}

#pragma mark - UIPopoverControllerDelegate Methods

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    if ([popoverController isEqual:self.typeAheadPopoverController]) {
        if ([self.searchBar.text isEqualToString:@""]) {
            [self hideSearchBar];
        } else {
            [self.searchBar resignFirstResponder];
        }
    }

    return YES;
}

@end
