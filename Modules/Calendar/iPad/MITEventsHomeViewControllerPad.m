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
@property (nonatomic, strong) UINavigationController *typeAheadNavigationController;
@property (nonatomic, strong) UISearchBar *typeAheadSearchBar;
@property (nonatomic, strong) MITEventSearchResultsViewController *resultsViewController;
@property (nonatomic, strong) UIViewController *currentCalendarListViewController;

@property (strong, nonatomic) UISearchBar *navigationSearchBar;
@property (strong, nonatomic) UIBarButtonItem *searchMagnifyingGlassBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *searchCancelBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *goToDateBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *searchFieldBarButtonItem;
@property (strong, nonatomic) MITCalendarsCalendar *currentSearchCategory;
@property (strong, nonatomic) UIBarButtonItem *searchCategoryBarButtonItem;
@property (nonatomic, strong) MITCalendarSelectionViewController *currentSearchCategorySelectionViewController;
@property (nonatomic, strong) NSString *currentSearchTerm;
@property (nonatomic, assign) BOOL isInSearchMode;

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
@property (nonatomic, strong) NSArray *splitViewConstraints;

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
    self.navigationController.toolbar.translucent = NO;
    self.title = @"All MIT Events";
    [self setupViewControllers];
    [self setupRightBarButtonItems];
    [self setupToolbar];
    [self setupExtendedNavBar];
    [self setupDayPickerController];
    [self constrainSplitViewToExtendedNavBar];
    
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
    [self showGeneralRightBarButtonItems];
}

- (void)hideSearchBar
{
    self.splitViewController.viewControllers = @[self.currentCalendarListViewController, self.eventDetailViewController];

    self.navigationSearchBar.text = @"";
    self.typeAheadSearchBar.text = @"";
    [self showGeneralRightBarButtonItems];

    if ([self.currentCalendarListViewController isEqual:self.eventsPageViewController]) {
        MITEventsTableViewController *currentlyDisplayedController = (MITEventsTableViewController *)self.eventsPageViewController.viewControllers[0];
        if (currentlyDisplayedController.events.count > 0) {
            self.eventDetailViewController.event = currentlyDisplayedController.events[0];
        } else {
            self.eventDetailViewController.event = nil;
        }
    }
}

- (void)showSearchPopover
{
    [self setupTypeAheadNavigationController];
    self.typeAheadPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.typeAheadNavigationController];
    self.typeAheadPopoverController.delegate = self;
    [self.typeAheadPopoverController presentPopoverFromBarButtonItem:self.searchMagnifyingGlassBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];

    [self.navigationSearchBar becomeFirstResponder];
}

#pragma mark - Search Mode Nav Bar

- (void)enableSearchModeNavBar
{
    [self showSearchModeRightBarButtonItems];
    [self hideExtendedNavBar];
}

- (void)showExtendedNavBarAndStandardDisplay
{
    [self showGeneralRightBarButtonItems];
    [self setupExtendedNavBar];
    [self setupDayPickerController];
    [self alignExtendedNavBarAndDayPickerCollectionView];
    [self.dayPickerController reloadCollectionView];
    [self constrainSplitViewToExtendedNavBar];
}

- (void)hideExtendedNavBar
{
    [self constrainSplitViewToNormalNavBar];
    [self.navigationController.navigationBar restoreShadow];
    [self.extendedNavBarView removeFromSuperview];
}

- (void)showSearchModeRightBarButtonItems
{
    if (!self.searchCancelBarButtonItem) {
        self.searchCancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                       target:self
                                                                                       action:@selector(cancelButtonPressed:)];
    }
    
    UIBarButtonItem *searchBarAsBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.navigationSearchBar];
    
    // TODO: Insert calendar selection drop down into bar button items
    self.navigationItem.rightBarButtonItems = @[self.searchCancelBarButtonItem, searchBarAsBarButtonItem, self.searchCategoryBarButtonItem];
}

- (void)showGeneralRightBarButtonItems
{
    if (!self.searchMagnifyingGlassBarButtonItem) {
        self.searchMagnifyingGlassBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"global/search"]
                                                                                   style:UIBarButtonItemStylePlain
                                                                                  target:self
                                                                                  action:@selector(searchButtonPressed:)];
    }
    
    if (!self.goToDateBarButtonItem) {
        self.goToDateBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"calendar/day_picker_button"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(showDatePickerButtonPressed:)];
    }
    
    self.navigationItem.rightBarButtonItems = @[self.searchMagnifyingGlassBarButtonItem, self.goToDateBarButtonItem];
}

#pragma mark - TypeAheadNavigationController

- (void)setupTypeAheadNavigationController
{
    if (!self.typeAheadNavigationController) {
        if (!self.typeAheadViewController) {
            [self setupTypeAheadViewController];
        }
        self.typeAheadNavigationController = [[UINavigationController alloc] initWithRootViewController:self.typeAheadViewController];
        self.typeAheadViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(typeAheadDoneButtonPressed:)];
        [self setupTypeAheadSearchBar];
    }
    
    [self.typeAheadSearchBar becomeFirstResponder];
}

- (void)setupTypeAheadSearchBar
{
    self.typeAheadSearchBar = [[UISearchBar alloc] initWithFrame:self.navigationController.navigationBar.bounds];
    self.typeAheadSearchBar.placeholder = @"Search All MIT Events";
    self.typeAheadSearchBar.showsCancelButton = NO;
    self.typeAheadSearchBar.delegate = self;
    self.typeAheadViewController.navigationItem.titleView = self.typeAheadSearchBar;
    [self.typeAheadNavigationController.navigationBar addSubview:self.typeAheadSearchBar];
}

- (void)typeAheadDoneButtonPressed:(UIBarButtonItem *)sender
{
    [self.typeAheadPopoverController dismissPopoverAnimated:YES];
}

#pragma mark - Navigation Bar Extension

- (void)setupExtendedNavBar
{
    if (![self.view.subviews containsObject:self.extendedNavBarView]) {
        UIColor *navbarGrey = [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0];
        self.extendedNavBarView = [MITExtendedNavBarView new];
        self.extendedNavBarView.backgroundColor = navbarGrey;
        [self.view addSubview:self.extendedNavBarView];
        [self.navigationController.navigationBar prepareForExtensionWithBackgroundColor:navbarGrey];
    }
    
    [self alignExtendedNavBarAndDayPickerCollectionView];
}

- (void)alignExtendedNavBarAndDayPickerCollectionView
{
    self.extendedNavBarView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), kMITEventHomeNavBarExtensionHeight);
    self.dayPickerController.view.frame = self.extendedNavBarView.bounds;
}

- (void)constrainSplitViewToExtendedNavBar
{
    if (self.splitViewConstraints.count > 0) {
        [self.view removeConstraints:self.splitViewConstraints];
    }
    
    self.splitViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[extendedNavBar]-0-[splitVC]-0-|" options:0 metrics:nil views:@{@"extendedNavBar": self.extendedNavBarView,
                                                                                                                                                    @"splitVC": self.splitViewController.view}];
    self.splitViewConstraints = [self.splitViewConstraints arrayByAddingObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[splitVC]-0-|" options:0 metrics:nil views:@{@"splitVC": self.splitViewController.view}]];
    [self.view addConstraints:self.splitViewConstraints];
}

- (void)constrainSplitViewToNormalNavBar
{
    if (self.splitViewConstraints.count > 0) {
        [self.view removeConstraints:self.splitViewConstraints];
    }
    
    self.splitViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[splitVC]-0-|" options:0 metrics:nil views:@{@"extendedNavBar": self.extendedNavBarView,
                                                                                                                                        @"splitVC": self.splitViewController.view}];
    self.splitViewConstraints = [self.splitViewConstraints arrayByAddingObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[splitVC]-0-|" options:0 metrics:nil views:@{@"splitVC": self.splitViewController.view}]];
    [self.view addConstraints:self.splitViewConstraints];
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
    [self showSearchPopover];
}

- (void)cancelButtonPressed:(UIBarButtonItem *)sender
{
    self.isInSearchMode = NO;
    [self hideSearchBar];
    [self showExtendedNavBarAndStandardDisplay];
    [self updateTitle];
}

- (void)beginSearch:(NSString *)searchString
{
    if (!self.isInSearchMode) {
        self.isInSearchMode = YES;
        
        self.title = nil;
        self.currentSearchTerm = searchString;
        self.currentSearchCategory = nil;
        self.currentSearchCategorySelectionViewController = [[MITCalendarSelectionViewController alloc] initWithStyle:UITableViewStylePlain];
        self.currentSearchCategorySelectionViewController.shouldHideRegistrar = YES;
        self.currentSearchCategorySelectionViewController.delegate = self;
        [self enableSearchModeNavBar];
    }
    
    self.eventDetailViewController.event = nil;
    self.navigationSearchBar.text = searchString;
    self.typeAheadSearchBar.text = searchString;
    [self.navigationSearchBar resignFirstResponder];
    [self.typeAheadPopoverController dismissPopoverAnimated:YES];
    self.splitViewController.viewControllers = @[self.resultsViewController, self.eventDetailViewController];
    [self.resultsViewController beginSearch:searchString];
}

- (void)searchCategoryButtonPressed
{
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.currentSearchCategorySelectionViewController];
    self.currentPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    [self.currentPopoverController presentPopoverFromBarButtonItem:self.searchCategoryBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (UIBarButtonItem *)searchCategoryBarButtonItem
{
    if (!_searchCategoryBarButtonItem) {
        _searchCategoryBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(searchCategoryButtonPressed)];
        [self updateSearchCategoryButtonTitle];
    }
    
    return _searchCategoryBarButtonItem;
}

- (void)setCurrentSearchCategory:(MITCalendarsCalendar *)currentSearchCategory
{
    if ([currentSearchCategory isEqualToCalendar:_currentSearchCategory]) {
        return;
    }
    
    _currentSearchCategory = currentSearchCategory;
    
    [self updateSearchCategoryButtonTitle];
}

- (void)updateSearchCategoryButtonTitle
{
    NSString *title = self.currentSearchCategory.name ? self.currentSearchCategory.name : @"All MIT Events";
    self.searchCategoryBarButtonItem.title = [NSString stringWithFormat:@"%@ %@", title, @"▾"];
}

#pragma mark - UISearchBarDelegate Methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self beginSearch:searchBar.text];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    if (!self.typeAheadPopoverController.isPopoverVisible && searchBar == self.typeAheadSearchBar) {
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
    self.eventsPageViewController.shouldIndicateCellSelectedState = YES;
    self.eventsPageViewController.calendarSelectionDelegate = self;
}

- (void)loadEvents
{
    self.eventsPageViewController.calendar = self.currentlySelectedCalendar;
    self.eventsPageViewController.category = self.currentlySelectedCategory;
    self.dayPickerController.currentlyDisplayedDate = [[NSDate date] startOfDay];
    // Force Update
    [self updateDisplayedDateFromDatePicker:self.dayPickerController.currentlyDisplayedDate];
}

- (void)setupEventDetailViewController
{
    self.eventDetailViewController = [[MITEventDetailViewController alloc] initWithNibName:nil bundle:nil];
}

- (void)setupSplitViewController
{
    self.splitViewController = [[MITEventsSplitViewController alloc] init];
    self.currentCalendarListViewController = self.eventsPageViewController;
    self.splitViewController.viewControllers = @[self.eventsPageViewController, self.eventDetailViewController];
    self.splitViewController.delegate = self;
    self.splitViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

    [self addChildViewController:self.splitViewController];
    self.splitViewController.view.frame = self.view.bounds;
    [self.view addSubview:self.splitViewController.view];
    [self.splitViewController didMoveToParentViewController:self];
}

- (void)setupTypeAheadViewController
{
    self.typeAheadViewController = [[MITEventSearchTypeAheadViewController alloc] initWithNibName:nil bundle:nil];
    self.typeAheadViewController.delegate = self;
}

- (void)setupResultsViewController
{
    self.resultsViewController = [[MITEventSearchResultsViewController alloc] initWithNibName:nil bundle:nil];
    self.resultsViewController.shouldIndicateCellSelectedState = YES;
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
    if (!self.dayPickerController) {
        self.dayPickerController = [MITDayPickerViewController new];
        self.dayPickerController.delegate = self;
        self.dayPickerController.view.frame = self.extendedNavBarView.bounds;
    }
    [self.dayPickerController willMoveToParentViewController:self];
    [self.extendedNavBarView addSubview:self.dayPickerController.view];
    [self addChildViewController:self.dayPickerController];
    [self.dayPickerController didMoveToParentViewController:self];
}

#pragma mark - MITDayPickerViewControllerDelegate

- (void)dayPickerViewController:(MITDayPickerViewController *)dayPickerViewController dateDidUpdate:(NSDate *)newDate fromOldDate:(NSDate *)oldDate
{
    [self updateDisplayedDateFromDatePicker:newDate];
}

- (void)updateDisplayedDateFromDatePicker:(NSDate *)date
{
    if ([self.currentlySelectedCalendar.identifier isEqualToString:self.masterCalendar.academicHolidaysCalendar.identifier]) {
        MITAcademicHolidaysCalendarViewController *academicCalendarVC = (MITAcademicHolidaysCalendarViewController *)self.currentCalendarListViewController;
        [academicCalendarVC scrollToDate:date];
    } else if ([self.currentlySelectedCalendar.identifier isEqualToString:self.masterCalendar.academicCalendar.identifier]) {
        MITAcademicCalendarViewController *academicCalendarVC = (MITAcademicCalendarViewController *)self.currentCalendarListViewController;
        [academicCalendarVC scrollToDate:date];
    } else {
        if (![self.eventsPageViewController.date isEqualToDateIgnoringTime:date]) {
            [self.eventsPageViewController moveToCalendar:self.currentlySelectedCalendar category:self.currentlySelectedCategory date:date animated:YES];
        }
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
    if ([viewController isEqual:self.calendarSelectionViewController]) {
        if (calendar) {
            self.currentlySelectedCalendar = calendar;
            self.currentlySelectedCategory = category;
            [self updateTitle];
            self.typeAheadViewController.currentCalendar = self.currentlySelectedCategory;
            self.resultsViewController.currentCalendar = self.currentlySelectedCategory;
            
            if ([calendar.identifier isEqualToString:[MITCalendarManager sharedManager].masterCalendar.academicHolidaysCalendar.identifier]) {
                MITAcademicHolidaysCalendarViewController *holidaysVC = [[MITAcademicHolidaysCalendarViewController alloc] init];
                self.currentCalendarListViewController = holidaysVC;
                self.eventDetailViewController.event = nil;
                [self hideExtendedNavBar];
            } else if ([calendar.identifier isEqualToString:[MITCalendarManager sharedManager].masterCalendar.academicCalendar.identifier]) {
                MITAcademicCalendarViewController *academicVC = [[MITAcademicCalendarViewController alloc] init];
                self.currentCalendarListViewController = academicVC;
                self.eventDetailViewController.event = nil;
                [self hideExtendedNavBar];
            } else {
                [self showExtendedNavBarAndStandardDisplay];
                self.currentCalendarListViewController = self.eventsPageViewController;
                [self.eventsPageViewController moveToCalendar:self.currentlySelectedCalendar
                                                     category:self.currentlySelectedCategory
                                                         date:self.dayPickerController.currentlyDisplayedDate
                                                     animated:YES];
            }
            
            self.splitViewController.viewControllers = @[self.currentCalendarListViewController, self.eventDetailViewController];
        }
        
        [self.calendarSelectorPopoverController dismissPopoverAnimated:YES];
    } else if ([viewController isEqual:self.currentSearchCategorySelectionViewController]) {
        self.currentSearchCategory = category;
        self.resultsViewController.currentCalendar = category;
        [self.resultsViewController beginSearch:self.currentSearchTerm];
        [self.currentPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)updateTitle
{
    MITCalendarsCalendar *calendarForTitle;
    if (self.currentlySelectedCategory) {
        calendarForTitle = self.currentlySelectedCategory;
    } else {
        calendarForTitle = self.currentlySelectedCalendar;
    }
    
    if (calendarForTitle.categories.count > 0) {
        if (calendarForTitle == self.masterCalendar.eventsCalendar) {
            self.title = @"All MIT Events";
        } else {
            self.title = [NSString stringWithFormat:@"All %@", calendarForTitle.name];
        }
    } else if (calendarForTitle) {
        self.title = calendarForTitle.name;
    }
}

#pragma mark - Toolbar Button Presses

- (void)todayButtonPressed:(id)sender
{
    NSDate *today = [[NSDate date] startOfDay];
    self.dayPickerController.currentlyDisplayedDate = today;
    
    if ([self.currentCalendarListViewController isKindOfClass:[MITAcademicCalendarViewController class]]) {
        [(MITAcademicCalendarViewController *)self.currentCalendarListViewController scrollToDate:today];
    } else if ([self.currentCalendarListViewController isKindOfClass:[MITAcademicHolidaysCalendarViewController class]]) {
        [(MITAcademicHolidaysCalendarViewController *)self.currentCalendarListViewController scrollToDate:today];
    }
    
    if ([self.splitViewController.viewControllers containsObject:self.resultsViewController]) {
        [self.resultsViewController scrollToToday];
    }
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
        [self.resultsViewController selectFirstRow];
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
        if ([self.navigationSearchBar.text isEqualToString:@""]) {
            [self hideSearchBar];
        } else {
            [self.navigationSearchBar resignFirstResponder];
        }
    }

    return YES;
}

#pragma mark - Getters | Setters

- (UISearchBar *)navigationSearchBar
{
    if (!_navigationSearchBar) {
        _navigationSearchBar = [[UISearchBar alloc] init];
        _navigationSearchBar.searchBarStyle = UISearchBarStyleMinimal;
        _navigationSearchBar.bounds = CGRectMake(0, 0, 260, 44);
        _navigationSearchBar.showsCancelButton = YES;
        _navigationSearchBar.showsCancelButton = NO;
        _navigationSearchBar.placeholder = @"Search";
        _navigationSearchBar.delegate = self;
    }
    return _navigationSearchBar;
}
@end
