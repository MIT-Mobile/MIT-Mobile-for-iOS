#import "MITEventsHomeViewController.h"
#import "MITDayOfTheWeekCell.h"
#import "MITCalendarEventCell.h"
#import "MITCalendarDataManager.h"
#import "UIKit+MITAdditions.h"
#import "NSDate+MITAdditions.h"
#import "MITDatePickerViewController.h"
#import "MITEventDetailViewController.h"
#import "MITCalendarSelectionViewController.h"
#import "MITCalendarWebservices.h"
#import "MITCalendarManager.h"
#import "MITEventSearchViewController.h"

#import "MITCalendarPageViewController.h"

typedef NS_ENUM(NSInteger, MITSlidingAnimationType){
    MITSlidingAnimationTypeNone,
    MITSlidingAnimationTypeForward,
    MITSlidingAnimationTypeBackward
};

static const CGFloat kSlidingAnimationSpan = 40.0;
static const NSTimeInterval kSlidingAnimationDuration = 0.3;

static NSString *const kMITDayOfTheWeekCell = @"MITDayOfTheWeekCell";
static NSString *const kMITCalendarEventCell = @"MITCalendarEventCell";

@interface MITEventsHomeViewController () <UICollectionViewDataSource, UICollectionViewDelegate, MITDatePickerViewControllerDelegate, MITCalendarSelectionDelegate, MITCalendarPageViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *dayPickerContainerView;
@property (weak, nonatomic) IBOutlet UICollectionView *dayPickerCollectionView;
@property (weak, nonatomic) IBOutlet UIButton *datePickerButton;

@property (weak, nonatomic) IBOutlet UILabel *todaysDateLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *todaysDateLabelCenterConstraint;
@property (strong, nonatomic) NSDateFormatter *dayLabelDateFormatter;

@property (weak, nonatomic) UIView *navBarSeparatorView;
@property (strong, nonatomic) UIView *repositionedNavBarSeparatorView;

@property (nonatomic) CGFloat pageWidth;

@property (nonatomic, strong) MITMasterCalendar *masterCalendar;

@property (nonatomic, strong) MITCalendarsCalendar *currentlySelectedCalendar;
@property (nonatomic, strong) MITCalendarsCalendar *currentlySelectedCategory;

@property (nonatomic, strong) NSArray *datesArray;

@property (nonatomic, strong) NSDate *currentlyDisplayedDate;

@property (nonatomic, strong) MITCalendarSelectionViewController *calendarSelectionViewController;

@property (nonatomic, strong) MITCalendarPageViewController *eventsController;
@property (weak, nonatomic) IBOutlet UIView *eventsTableContainerView;

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
    self.title = @"Events";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"global/search_magnifier.png"] style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonPressed)];
    
    self.currentlyDisplayedDate = [[NSDate date] beginningOfDay];
    [self updateDatesArray];
    [self setDateLabelWithDate:self.currentlyDisplayedDate animationType:MITSlidingAnimationTypeNone];

    [self setupExtendedNavBar];
    [self setupDayPickerCollectionView];
    [self setupEventsContainer];
    [self setupDatePickerButton];
   
    [[MITCalendarManager sharedManager] getCalendarsCompletion:^(MITMasterCalendar *masterCalendar, NSError *error) {
        if (masterCalendar) {
            self.masterCalendar = masterCalendar;
            self.currentlySelectedCalendar = masterCalendar.eventsCalendar;
            [self updateDisplayedCalendar:self.currentlySelectedCalendar category:nil date:self.currentlyDisplayedDate animated:NO];
        }
    }];

}

- (void)viewWillAppear:(BOOL)animated
{
    self.navBarSeparatorView.hidden = YES;
    
    [self registerForNotifications];
    [self centerDayPickerCollectionView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navBarSeparatorView.hidden = NO;
    
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
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    
    self.navBarSeparatorView = [self findHairlineImageViewUnder:navigationBar];
    
    self.repositionedNavBarSeparatorView = [[UIImageView alloc] initWithFrame:self.navBarSeparatorView.frame];
    self.repositionedNavBarSeparatorView.backgroundColor = [UIColor colorWithRed:150.0/255.0 green:152.0/255.0 blue:156.0/255.0 alpha:1.0];
    CGRect repositionedFrame = self.repositionedNavBarSeparatorView.frame;
    repositionedFrame.origin.y = 62.5;
    self.repositionedNavBarSeparatorView.frame = repositionedFrame;
    self.repositionedNavBarSeparatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.dayPickerContainerView addSubview:self.repositionedNavBarSeparatorView];
    
    navigationBar.opaque = YES;
    navigationBar.translucent = NO;
    UIColor *navbarGrey = [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0];
    [navigationBar setBarTintColor:navbarGrey];
    self.dayPickerContainerView.backgroundColor = navbarGrey;
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

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(calendarListLoaded:) name:kCalendarListsLoaded object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(calendarListLoadedFailed:) name:kCalendarListsFailedToLoad object:nil];
}

- (UIImageView *)findHairlineImageViewUnder:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findHairlineImageViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}

- (void)setupDayPickerCollectionView
{
    self.dayPickerCollectionView.backgroundColor = [UIColor clearColor];
    
    UINib *cellNib = [UINib nibWithNibName:kMITDayOfTheWeekCell bundle:nil];
    [self.dayPickerCollectionView registerNib:cellNib forCellWithReuseIdentifier:kMITDayOfTheWeekCell];
    
    self.pageWidth = self.dayPickerCollectionView.frame.size.width;
    
    self.dayPickerCollectionView.scrollsToTop = NO;
}

- (void)setupDatePickerButton
{
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(datePickerButtonPanned:)];
    [self.datePickerButton addGestureRecognizer:panGestureRecognizer];
    
    [self.datePickerButton addTarget:self action:@selector(datePickerButtonPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)searchButtonPressed
{
    MITEventSearchViewController *searchVC = [[MITEventSearchViewController alloc] initWithCategory:self.currentlySelectedCategory];
    UINavigationController *searchNavController = [[UINavigationController alloc] initWithRootViewController:searchVC];
    [self presentViewController:searchNavController animated:YES completion:nil];
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
    MITDayOfTheWeekCell *cell = [self.dayPickerCollectionView dequeueReusableCellWithReuseIdentifier:kMITDayOfTheWeekCell
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
    if (scrollView == self.dayPickerCollectionView) {
        [self updateDayPickerOffsetForInfiniteScrolling];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (scrollView == self.dayPickerCollectionView) {
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
    if ([cellDate isSameDayAsDate:self.currentlyDisplayedDate]) {
        cell.state = MITDayOfTheWeekStateSelected;
    }
    else {
        cell.state = MITDayOfTheWeekStateUnselected;
    }
    if ([cellDate isSameDayAsDate:[NSDate date]]){
        cell.state |= MITDayOfTheWeekStateToday;
    }
}

- (NSDate *)dateForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger adjustedIndex = indexPath.row;
    return self.datesArray[adjustedIndex];
}

#pragma mark - Date Picker Button

- (void)datePickerButtonPressed
{
    [self presentDatePicker];
}

- (void)datePickerButtonPanned:(UIPanGestureRecognizer *)pan
{
    static CGFloat dayPickerCollectionViewStartXOffset;
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        dayPickerCollectionViewStartXOffset = self.dayPickerCollectionView.contentOffset.x;
    }
    if (pan.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [pan velocityInView:self.view];
        
        if (ABS(velocity.x) > 250) {
            if (velocity.x > 0) {
                // Scroll left one week
                [self.dayPickerCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
            } else {
                // Scroll right one week
                [self.dayPickerCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:14 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
            }
        } else {
            CGFloat xTranslation = [pan translationInView:self.datePickerButton].x;
            
            if (ABS(xTranslation) > 190) {
                if (xTranslation > 0) {
                    // Scroll left one week
                    [self.dayPickerCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
                } else {
                    // Scroll right one week
                    [self.dayPickerCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:14 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
                }
            } else {
                // Return daypicker collectionview to current week
                [self.dayPickerCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:7 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
            }
        }
    } else {
        CGFloat xTranslation = [pan translationInView:self.datePickerButton].x;
        
        CGPoint dayPickerOffset = self.dayPickerCollectionView.contentOffset;
        dayPickerOffset.x = dayPickerCollectionViewStartXOffset - xTranslation;
        self.dayPickerCollectionView.contentOffset = dayPickerOffset;
    }
}

- (void)calendarListLoaded:(NSNotification *)ntfn
{
    
}

- (void)calendarListLoadedFailed:(NSNotification *)ntfn
{
    
}

#pragma mark - Toolbar Buttons

- (IBAction)todayButtonPressed:(id)sender
{
    [self updateDisplayedCalendar:nil category:nil date:[[NSDate date] beginningOfDay] animated:YES];
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
    if (calendar) {
        self.eventsController.calendar =
        self.currentlySelectedCalendar = calendar;
    }
    
    if (category) {
        self.eventsController.category =
        self.currentlySelectedCategory = category;
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
    MITSlidingAnimationType slidingDirection = MITSlidingAnimationTypeForward;
    if ([self.currentlyDisplayedDate compare:date] == NSOrderedDescending) {
        slidingDirection = MITSlidingAnimationTypeBackward;
    }
    self.currentlyDisplayedDate = date;
    
    [self updateDatesArray];
    [self setDateLabelWithDate:date animationType:slidingDirection];
    [self.dayPickerCollectionView reloadData];
    [self centerDayPickerCollectionView];
}

- (void)centerDayPickerCollectionView
{
    [self.dayPickerCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:7 inSection:0]
                                         atScrollPosition:UICollectionViewScrollPositionLeft
                                                 animated:NO];
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
