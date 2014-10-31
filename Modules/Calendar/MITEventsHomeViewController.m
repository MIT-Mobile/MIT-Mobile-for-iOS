#import "MITEventsHomeViewController.h"
#import "MITDayOfTheWeekCell.h"
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

typedef NS_ENUM(NSInteger, MITSlidingAnimationType){
    MITSlidingAnimationTypeNone,
    MITSlidingAnimationTypeForward,
    MITSlidingAnimationTypeBackward
};

static const CGFloat kSlidingAnimationSpan = 40.0;
static const NSTimeInterval kSlidingAnimationDuration = 0.3;

static NSString *const kMITCalendarEventCell = @"MITCalendarEventCell";
static NSString * const MITDayPickerCollectionViewCellIdentifier = @"MITDayPickerCollectionViewCellIdentifier";

@interface MITEventsHomeViewController () <UICollectionViewDataSource, UICollectionViewDelegate, MITDatePickerViewControllerDelegate, MITCalendarSelectionDelegate, MITCalendarPageViewControllerDelegate>

@property (weak, nonatomic) IBOutlet MITExtendedNavBarView *dayPickerContainerView;
@property (weak, nonatomic) IBOutlet UICollectionView *dayPickerCollectionView;

@property (weak, nonatomic) IBOutlet UILabel *todaysDateLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *todaysDateLabelCenterConstraint;
@property (strong, nonatomic) NSDateFormatter *dayLabelDateFormatter;

@property (nonatomic) CGFloat pageWidth;

@property (nonatomic, strong) MITMasterCalendar *masterCalendar;

@property (nonatomic, strong) MITCalendarsCalendar *currentlySelectedCalendar;
@property (nonatomic, strong) MITCalendarsCalendar *currentlySelectedCategory;

@property (nonatomic, strong) NSArray *datesArray;

@property (nonatomic, strong) NSDate *currentlyDisplayedDate;

@property (nonatomic, strong) MITCalendarSelectionViewController *calendarSelectionViewController;

@property (nonatomic, strong) MITCalendarPageViewController *eventsController;
@property (weak, nonatomic) IBOutlet UIView *eventsTableContainerView;

@property (nonatomic) BOOL dayPickerShouldUpdateAfterCallback;

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
    
    self.currentlyDisplayedDate = [[NSDate date] startOfDay];
    [self updateDatesArray];
    [self setDateLabelWithDate:self.currentlyDisplayedDate animationType:MITSlidingAnimationTypeNone];

    [self setupExtendedNavBar];
    [self setupDayPickerCollectionView];
    [self setupEventsContainer];
   
    [[MITCalendarManager sharedManager] getCalendarsCompletion:^(MITMasterCalendar *masterCalendar, NSError *error) {
        if (masterCalendar) {
            self.masterCalendar = masterCalendar;
            self.currentlySelectedCalendar = masterCalendar.eventsCalendar;
            self.dayPickerShouldUpdateAfterCallback = YES;
            [self updateDisplayedCalendar:self.currentlySelectedCalendar category:nil date:self.currentlyDisplayedDate animated:NO];
        }
    }];

}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController.navigationBar removeShadow];
    
    [self centerDayPickerCollectionView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController.navigationBar restoreShadow];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup Methods

- (void)setupExtendedNavBar
{
    UIColor *navbarGrey = [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0];
    
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

- (void)setupDayPickerCollectionView
{
    self.dayPickerCollectionView.backgroundColor = [UIColor clearColor];
    
    UINib *cellNib = [UINib nibWithNibName:MITPhoneDayOfTheWeekCellNibName bundle:nil];
    [self.dayPickerCollectionView registerNib:cellNib forCellWithReuseIdentifier:MITDayPickerCollectionViewCellIdentifier];
    
    self.pageWidth = self.dayPickerCollectionView.frame.size.width;
    
    self.dayPickerCollectionView.scrollsToTop = NO;
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

#pragma mark - Day of the week Collection View Datasource/Delegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 21;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MITDayOfTheWeekCell *cell = [self.dayPickerCollectionView dequeueReusableCellWithReuseIdentifier:MITDayPickerCollectionViewCellIdentifier
                                                                                        forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;

}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.dayPickerCollectionView deselectItemAtIndexPath:indexPath animated:NO];
    [self updateDisplayedCalendar:nil category:nil date:[self dateForIndexPath:indexPath] animated:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == self.dayPickerCollectionView && self.dayPickerShouldUpdateAfterCallback) {
        [self updateDayPickerOffsetForInfiniteScrolling];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (scrollView == self.dayPickerCollectionView && self.dayPickerShouldUpdateAfterCallback) {
        [self updateDayPickerOffsetForInfiniteScrolling];
    }
}

- (void)updateDayPickerOffsetForInfiniteScrolling
{
    if (self.dayPickerCollectionView.contentOffset.x <= 0 ) {
        [self updateDisplayedCalendar:nil category:nil date:[self.currentlyDisplayedDate dateBySubtractingWeek] animated:YES];
    }
    else if (self.dayPickerCollectionView.contentOffset.x >= self.pageWidth * 2) {
        [self updateDisplayedCalendar:nil category:nil date:[self.currentlyDisplayedDate dateByAddingWeek] animated:YES];
    }
}


- (void)configureCell:(MITDayOfTheWeekCell *)cell  forIndexPath:(NSIndexPath *)indexPath
{
    cell.dayOfTheWeek = indexPath.row % 7;
    
    NSDate *cellDate = [self dateForIndexPath:indexPath];
    if ([cellDate isEqualToDateIgnoringTime:self.currentlyDisplayedDate]) {
        cell.state = MITDayOfTheWeekStateSelected;
    }
    else {
        cell.state = MITDayOfTheWeekStateUnselected;
    }
    if ([cellDate isEqualToDateIgnoringTime:[NSDate date]]){
        cell.state |= MITDayOfTheWeekStateToday;
    }
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:cellDate];
    cell.dayOfTheMonth = components.day;
}

- (NSDate *)dateForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger adjustedIndex = indexPath.row;
    return self.datesArray[adjustedIndex];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = CGRectGetHeight(collectionView.bounds);
    CGFloat width = CGRectGetWidth(collectionView.bounds) / 7.0;
    return CGSizeMake(width, height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0;
}

#pragma mark - Toolbar Buttons

- (IBAction)todayButtonPressed:(id)sender
{
    [self updateDisplayedCalendar:nil category:nil date:[[NSDate date] startOfDay] animated:YES];
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
            [self.dayPickerContainerView layoutIfNeeded];
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
        [self updateDisplayedCalendar:self.currentlySelectedCalendar category:self.currentlySelectedCategory date:self.currentlyDisplayedDate animated:NO];
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
    [self updateDisplayedDate:date];
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
        self.title = [NSString stringWithFormat:@"All %@", calendarForTitle.name];
    } else if (calendarForTitle) {
        self.title = calendarForTitle.name;
    }
    
    if ([date isEqualToDate:self.currentlyDisplayedDate]) {
        animated = NO;
    }
    else {
        [self updateDisplayedDate:date];
    }
    
    [self.eventsController moveToCalendar:self.currentlySelectedCalendar
                                 category:self.currentlySelectedCategory
                                     date:self.currentlyDisplayedDate
                                 animated:animated];
}

- (void)updateDisplayedDate:(NSDate *)date
{
    MITSlidingAnimationType labelSlidingAnimationType = MITSlidingAnimationTypeForward;
    if ([self.currentlyDisplayedDate compare:date] == NSOrderedDescending) {
        labelSlidingAnimationType = MITSlidingAnimationTypeBackward;
    }
    
    [self setDateLabelWithDate:date animationType:labelSlidingAnimationType];
    
    MITSlidingAnimationType datePickerSlidingAnimationType = MITSlidingAnimationTypeNone;
    if ([date dateFallsBetweenStartDate:self.datesArray[0] endDate:self.datesArray[6]]) {
        datePickerSlidingAnimationType = MITSlidingAnimationTypeBackward;
    }
    else if ([date dateFallsBetweenStartDate:self.datesArray[14] endDate:self.datesArray[20]]) {
        datePickerSlidingAnimationType = MITSlidingAnimationTypeForward;
    }
    
    self.currentlyDisplayedDate = date;
    
    switch (datePickerSlidingAnimationType) {
        case MITSlidingAnimationTypeNone:
            [self updateDatesArray];
            [self.dayPickerCollectionView reloadData];
            [self centerDayPickerCollectionView];
            break;
            
        case MITSlidingAnimationTypeForward:
            [self animateDayPickerCollectionViewForward];
            break;
            
        case MITSlidingAnimationTypeBackward:
            [self animateDayPickerCollectionViewBackwards];
            break;
            
        default:
            break;
    }
}

- (void)centerDayPickerCollectionView
{
    [self.dayPickerCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:7 inSection:0]
                                         atScrollPosition:UICollectionViewScrollPositionLeft
                                                 animated:NO];
}

- (void)delayedCenterDayPickerCollectionView
{
    [self updateDatesArray];
    [self.dayPickerCollectionView reloadData];
    [self centerDayPickerCollectionView];
    self.dayPickerShouldUpdateAfterCallback = YES;
}

- (void)animateDayPickerCollectionViewBackwards
{
    self.dayPickerShouldUpdateAfterCallback = NO;
    [self.dayPickerCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
    [self performSelector:@selector(delayedCenterDayPickerCollectionView) withObject:nil afterDelay:kSlidingAnimationDuration];
}

- (void)animateDayPickerCollectionViewForward
{
    self.dayPickerShouldUpdateAfterCallback = NO;
    [self.dayPickerCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:14 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
    [self performSelector:@selector(delayedCenterDayPickerCollectionView) withObject:nil afterDelay:kSlidingAnimationDuration];
}


- (void)updateDatesArray
{
    NSMutableArray *newDatesArray = [[NSMutableArray alloc] init];
    
    NSDate *lastWeek = [self.currentlyDisplayedDate dateBySubtractingWeek];
    NSDate *nextWeek = [self.currentlyDisplayedDate dateByAddingWeek];
    
    [newDatesArray addObjectsFromArray:[lastWeek datesInWeek]];
    [newDatesArray addObjectsFromArray:[self.currentlyDisplayedDate datesInWeek]];
    [newDatesArray addObjectsFromArray:[nextWeek datesInWeek]];
    
    self.datesArray = newDatesArray;
}

@end
