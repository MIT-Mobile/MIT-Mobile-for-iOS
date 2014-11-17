#import "MITEventsHomeViewController.h"
#import "MITCalendarEventCell.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "MITDatePickerViewController.h"
#import "MITEventDetailViewController.h"
#import "MITCalendarSelectionViewController.h"
#import "MITCalendarWebservices.h"
#import "MITCalendarManager.h"
#import "MITEventSearchViewController.h"
#import "MITCalendarPageViewController.h"
#import "UINavigationBar+ExtensionPrep.h"
#import "MITExtendedNavBarView.h"
#import "MITDayPickerViewController.h"

typedef NS_ENUM(NSInteger, MITSlidingAnimationType){
    MITSlidingAnimationTypeNone,
    MITSlidingAnimationTypeForward,
    MITSlidingAnimationTypeBackward
};

static const CGFloat kSlidingAnimationSpan = 40.0;
static const NSTimeInterval kSlidingAnimationDuration = 0.3;
static const CGFloat MITDayPickerControllerHeight = 64.0;

static NSString *const kMITCalendarEventCell = @"MITCalendarEventCell";
static NSString * const MITDayPickerCollectionViewCellIdentifier = @"MITDayPickerCollectionViewCellIdentifier";

@interface MITEventsHomeViewController () <MITDayPickerViewControllerDelegate, MITDatePickerViewControllerDelegate, MITCalendarSelectionDelegate, MITCalendarPageViewControllerDelegate>

@property (weak, nonatomic) IBOutlet MITExtendedNavBarView *dayPickerContainerView;

@property (weak, nonatomic) IBOutlet UILabel *todaysDateLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *todaysDateLabelCenterConstraint;
@property (strong, nonatomic) NSDateFormatter *dayLabelDateFormatter;

@property (nonatomic) CGFloat pageWidth;

@property (nonatomic, strong) MITMasterCalendar *masterCalendar;

@property (nonatomic, strong) MITCalendarsCalendar *currentlySelectedCalendar;
@property (nonatomic, strong) MITCalendarsCalendar *currentlySelectedCategory;

@property (nonatomic, strong) MITCalendarSelectionViewController *calendarSelectionViewController;

@property (nonatomic, strong) MITCalendarPageViewController *eventsController;
@property (weak, nonatomic) IBOutlet UIView *eventsTableContainerView;

@property (strong, nonatomic) MITDayPickerViewController *dayPickerController;

@end

@implementation MITEventsHomeViewController

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
    // Do any additional setup after loading the view from its nib.
    self.title = @"All MIT Events";
    [self setupRightBarButtonItems];
    
    [self setupExtendedNavBar];
    [self setupEventsContainer];
    [self setupDayPickerController];
    [self setDateLabelWithDate:self.dayPickerController.currentlyDisplayedDate animationType:MITSlidingAnimationTypeNone];
   
    [[MITCalendarManager sharedManager] getCalendarsCompletion:^(MITMasterCalendar *masterCalendar, NSError *error) {
        if (masterCalendar) {
            self.masterCalendar = masterCalendar;
            self.currentlySelectedCalendar = masterCalendar.eventsCalendar;
            [self updateDisplayedCalendar:self.currentlySelectedCalendar category:nil date:self.dayPickerController.currentlyDisplayedDate animated:NO];
        }
    }];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupExtendedNavBar]; // Coming back from another vc messes up nav bar
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController.navigationBar restoreShadow];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup Methods

- (void)setupExtendedNavBar
{
    UIColor *navbarGrey = [UIColor mit_navBarColor];
    
    [self.navigationController.navigationBar prepareForExtensionWithBackgroundColor:navbarGrey];
    
    self.dayPickerContainerView.backgroundColor = navbarGrey;
    [self.view bringSubviewToFront:self.dayPickerContainerView];
}

- (void)setupRightBarButtonItems
{
    UIButton *dayPickerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [dayPickerButton setImage:[UIImage imageNamed:@"calendar/day_picker_button"] forState:UIControlStateNormal];
    [dayPickerButton setTintColor:self.navigationController.navigationBar.tintColor];
    [dayPickerButton addTarget:self action:@selector(dayPickerButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [searchButton setImage:[UIImage imageNamed:MITImageBarButtonSearchMagnifier] forState:UIControlStateNormal];
    [searchButton setTintColor:self.navigationController.navigationBar.tintColor];
    [searchButton addTarget:self action:@selector(searchButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat buttonWidth = 30.0;
    CGFloat buttonHeight = 30.0;
    CGFloat buttonSpacing = 10.0;
    CGFloat totalWidth = buttonWidth + buttonSpacing + buttonWidth;
    
    UIView *buttonHousingView = [UIView new];
    buttonHousingView.bounds = CGRectMake(0, 0, totalWidth, buttonHeight);
    
    dayPickerButton.frame = CGRectMake(0, 0, buttonWidth, buttonHeight);
    searchButton.frame = CGRectMake(totalWidth - buttonWidth, 0, buttonWidth, buttonHeight);
    [buttonHousingView addSubview:dayPickerButton];
    [buttonHousingView addSubview:searchButton];
    
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacer.width = -10; // Shift 10 pts to the right
    self.navigationItem.rightBarButtonItems = @[spacer, [[UIBarButtonItem alloc] initWithCustomView:buttonHousingView]];
}

- (void)setupEventsContainer
{
    self.eventsController = [[MITCalendarPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                     navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                   options:nil];
    self.eventsController.calendarSelectionDelegate = self;
    [self addChildViewController:self.eventsController];
    self.eventsController.view.frame = self.eventsTableContainerView.bounds;
    [self.eventsTableContainerView addSubview:self.eventsController.view];
    [self.eventsController didMoveToParentViewController:self];
}

- (void)setupDayPickerController
{
    self.dayPickerController = [MITDayPickerViewController new];
    self.dayPickerController.currentlyDisplayedDate = [[NSDate date] startOfDay];
    self.dayPickerController.delegate = self;
    CGFloat containerWidth = CGRectGetWidth(self.dayPickerContainerView.bounds);
    self.dayPickerController.view.frame = CGRectMake(0, 0, containerWidth, MITDayPickerControllerHeight);
    
    [self.dayPickerController willMoveToParentViewController:self];
    [self.dayPickerContainerView addSubview:self.dayPickerController.view];
    [self addChildViewController:self.dayPickerController];
    [self.dayPickerController didMoveToParentViewController:self];
}

#pragma mark - MITDayPickerViewControllerDelegate

- (void)dayPickerViewController:(MITDayPickerViewController *)dayPickerViewController dateDidUpdate:(NSDate *)newDate fromOldDate:(NSDate *)oldDate
{
    if (![self.eventsController.date isEqualToDateIgnoringTime:newDate]) {
        [self.eventsController moveToCalendar:self.currentlySelectedCalendar category:self.currentlySelectedCategory date:newDate animated:YES];
    }
    [self updateDisplayedDate:newDate fromOldDate:oldDate];
}

#pragma mark - Rotation

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    CGFloat containerWidth = CGRectGetWidth(self.dayPickerContainerView.bounds);
    self.dayPickerController.view.frame = CGRectMake(0, 0, containerWidth, MITDayPickerControllerHeight);
}

#pragma mark - Button Presses

- (void)searchButtonPressed
{
    MITEventSearchViewController *searchVC = [[MITEventSearchViewController alloc] initWithCategory:self.currentlySelectedCategory];
    UINavigationController *searchNavController = [[UINavigationController alloc] initWithRootViewController:searchVC];
    [self presentViewController:searchNavController animated:NO completion:nil];
}

- (void)dayPickerButtonPressed
{
    [self presentDatePicker];
}

#pragma mark - Toolbar Buttons

- (IBAction)todayButtonPressed:(id)sender
{
    self.dayPickerController.currentlyDisplayedDate = [[NSDate date] startOfDay];
}

#pragma mark - Animating Date Label

- (void)setDateLabelWithDate:(NSDate *)date animationType:(MITSlidingAnimationType)animationType
{
    NSString *dateString = [self.dayLabelDateFormatter stringFromDate:date];
    if (animationType == MITSlidingAnimationTypeNone) {
        self.todaysDateLabel.text = dateString;
    } else {
        CGPoint dateLabelCenter = self.todaysDateLabel.center;
        CGPoint initialTempLabelCenter;
        switch (animationType) {
            case MITSlidingAnimationTypeForward:
                initialTempLabelCenter = CGPointApplyAffineTransform(dateLabelCenter,
                                                                     CGAffineTransformMakeTranslation(kSlidingAnimationSpan, 0));
                self.todaysDateLabelCenterConstraint.constant = kSlidingAnimationSpan;
                break;
            case MITSlidingAnimationTypeBackward:
                initialTempLabelCenter = CGPointApplyAffineTransform(dateLabelCenter,
                                                                     CGAffineTransformMakeTranslation(-kSlidingAnimationSpan, 0));
                self.todaysDateLabelCenterConstraint.constant = -kSlidingAnimationSpan;
                break;
            default:
                break;
        }
        
        UILabel *tempLabel = [self tempDateLabelWithDateString:dateString];
        tempLabel.center = initialTempLabelCenter;
        tempLabel.alpha = 0;
        [self.dayPickerContainerView addSubview:tempLabel];
        
        [UIView animateWithDuration:kSlidingAnimationDuration animations:^{
            tempLabel.center = dateLabelCenter;
            tempLabel.alpha = 1;
            self.todaysDateLabel.alpha = 0;
        } completion:^(BOOL finished) {
            [tempLabel removeFromSuperview];
            self.todaysDateLabel.text = dateString;
            self.todaysDateLabelCenterConstraint.constant = 0;
            self.todaysDateLabel.alpha = 1;
            [self.dayPickerContainerView layoutIfNeeded];
        }];
    }
}

- (UILabel *)tempDateLabelWithDateString:(NSString *)dateString
{
    UILabel *tempLabel = [[UILabel alloc] initWithFrame:self.todaysDateLabel.frame];
    tempLabel.backgroundColor = [UIColor clearColor];
    tempLabel.textAlignment = NSTextAlignmentCenter;
    tempLabel.textColor = self.todaysDateLabel.textColor;
    tempLabel.font = self.todaysDateLabel.font;
    tempLabel.text = dateString;
    [tempLabel sizeToFit];
    return tempLabel;
}

- (NSDateFormatter *)dayLabelDateFormatter
{
    if (!_dayLabelDateFormatter) {
        _dayLabelDateFormatter = [[NSDateFormatter alloc] init];
        [_dayLabelDateFormatter setDateStyle:NSDateFormatterFullStyle];
    }
    return _dayLabelDateFormatter;
}

#pragma mark - Date Picker 
- (void)presentDatePicker
{
    MITDatePickerViewController *datePicker = [[MITDatePickerViewController alloc] initWithNibName:nil bundle:nil];
    datePicker.delegate = self;
    UINavigationController *navContainerController = [[UINavigationController alloc] initWithRootViewController:datePicker];
    [self presentViewController:navContainerController animated:YES completion:NULL];
}

- (void)datePickerDidCancel:(MITDatePickerViewController *)datePicker
{
    [self dismissViewControllerAnimated:datePicker completion:NULL];
}

- (void)datePicker:(MITDatePickerViewController *)datePicker didSelectDate:(NSDate *)date
{
    [self updateDisplayedCalendar:nil category:nil date:date animated:NO];
    [self dismissViewControllerAnimated:datePicker completion:NULL];
}

#pragma mark - Calendar Selection
- (IBAction)presentCalendarSelectionPressed:(id)sender
{
    UINavigationController *navContainerController = [[UINavigationController alloc] initWithRootViewController:self.calendarSelectionViewController];
    [self presentViewController:navContainerController animated:YES completion:NULL];
}

- (void)calendarSelectionViewController:(MITCalendarSelectionViewController *)viewController
                      didSelectCalendar:(MITCalendarsCalendar *)calendar
                               category:(MITCalendarsCalendar *)category
{
    if (calendar) {
        self.currentlySelectedCalendar = calendar;
        self.currentlySelectedCategory = category;
        [self updateDisplayedCalendar:self.currentlySelectedCalendar category:self.currentlySelectedCategory date:self.dayPickerController.currentlyDisplayedDate animated:NO];
    }
    
    [viewController dismissViewControllerAnimated:YES completion:NULL];
}

- (MITCalendarSelectionViewController *)calendarSelectionViewController
{
    if (!_calendarSelectionViewController)
    {
        _calendarSelectionViewController = [[MITCalendarSelectionViewController alloc] initWithStyle:UITableViewStyleGrouped];
        _calendarSelectionViewController.delegate = self;
    }
    return _calendarSelectionViewController;
}

#pragma mark - Events Controller Delegate

- (void)calendarPageViewController:(MITCalendarPageViewController *)viewController didSelectEvent:(MITCalendarsEvent *)event
{
    MITEventDetailViewController *detailVC = [[MITEventDetailViewController alloc] initWithNibName:nil bundle:nil];
    detailVC.event = event;
    [self.navigationController pushViewController:detailVC animated:YES];
}

- (void)calendarPageViewController:(MITCalendarPageViewController *)viewController didSwipeToDate:(NSDate *)date
{
    self.dayPickerController.currentlyDisplayedDate = date;
}

#pragma mark - Display Refreshing

- (void)updateDisplayedCalendar:(MITCalendarsCalendar *)calendar
                       category:(MITCalendarsCalendar *)category
                           date:(NSDate *)date
                       animated:(BOOL)animated
{
    MITCalendarsCalendar *calendarForTitle;
    if (calendar) {
        self.eventsController.calendar =
        self.currentlySelectedCalendar =
        calendarForTitle = calendar;
    }
    if (category) {
        self.eventsController.category =
        self.currentlySelectedCategory =
        calendarForTitle = category;
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
    
    if ([date isEqualToDateIgnoringTime:self.dayPickerController.currentlyDisplayedDate]) {
        animated = NO;
    }
    
    [self.eventsController moveToCalendar:self.currentlySelectedCalendar
                                 category:self.currentlySelectedCategory
                                     date:self.dayPickerController.currentlyDisplayedDate
                                 animated:animated];
}

- (void)updateDisplayedDate:(NSDate *)newDate fromOldDate:(NSDate *)oldDate
{
    MITSlidingAnimationType labelSlidingAnimationType = MITSlidingAnimationTypeForward;
    if ([oldDate compare:newDate] == NSOrderedDescending) {
        labelSlidingAnimationType = MITSlidingAnimationTypeBackward;
    }
    
    [self setDateLabelWithDate:newDate animationType:labelSlidingAnimationType];
}

#pragma mark - Rotation

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
