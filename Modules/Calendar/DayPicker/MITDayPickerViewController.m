#import "MITDayPickerViewController.h"
#import "MITDayOfTheWeekCell.h"
#import "NSDate+MITDatePicker.h"

static NSString * const MITDayPickerControllerCellIdentifier = @"MITDayPickerControllerCellIdentifier";

@interface MITDayPickerViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *datesArray;
@property (nonatomic) BOOL shouldUpdateDayPickerOffesetAfterScrollviewDelegateCallback;
@end

@implementation MITDayPickerViewController

@synthesize currentlyDisplayedDate = _currentlyDisplayedDate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.shouldUpdateDayPickerOffesetAfterScrollviewDelegateCallback = YES;
    [self setupDayPickerCollectionView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self centerDayPickerCollectionView];
}

#pragma mark - Setup

- (void)setupDayPickerCollectionView
{
    [self updateDatesArray];
    UICollectionViewFlowLayout *flow = [UICollectionViewFlowLayout new];
    flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flow];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.frame = self.view.bounds;
    self.collectionView.pagingEnabled = YES;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.view addSubview:self.collectionView];
    
    NSString *nibName = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? MITPadDayOfTheWeekCellNibName : MITPhoneDayOfTheWeekCellNibName;
    UINib *dayCellNib = [UINib nibWithNibName:nibName bundle:nil];
    [self.collectionView registerNib:dayCellNib forCellWithReuseIdentifier:MITDayPickerControllerCellIdentifier];
    
    [self setupCollectionViewConstraints];
}

- (void)setupCollectionViewConstraints
{
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    [self.view addConstraints:@[leftConstraint, rightConstraint, topConstraint, bottomConstraint]];
}

#pragma mark - Rotation

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self reloadDayPicker];
}

#pragma mark - UICollectionViewDataSource

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
    MITDayOfTheWeekCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MITDayPickerControllerCellIdentifier forIndexPath:indexPath];
    
    NSDate *date = self.datesArray[indexPath.row];
    MITDayOfTheWeekState state = [self stateForDate:date];
    
    cell.todayColor = self.todayColor;
    cell.selectedDayColor = self.selectedDayColor;
    cell.date = date;
    cell.state = state;
    
    return cell;
}

- (MITDayOfTheWeekState)stateForDate:(NSDate *)date
{
    MITDayOfTheWeekState state;
    if ([date dp_isEqualToDateIgnoringTime:self.currentlyDisplayedDate]) {
        state = MITDayOfTheWeekStateSelected;
    }
    else {
        state = MITDayOfTheWeekStateUnselected;
    }
    
    if ([date dp_isEqualToDateIgnoringTime:[NSDate date]]){
        state |= MITDayOfTheWeekStateToday;
    }
    return state;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    self.currentlyDisplayedDate = self.datesArray[indexPath.row];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = CGRectGetHeight(self.view.bounds);
    CGFloat width = CGRectGetWidth(self.view.bounds) / 7.0;
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

#pragma mark - Collection View Utilities

- (void)reloadDayPicker
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
        [self centerDayPickerCollectionView];
    });
}

#pragma mark - Scrolling

- (void)centerDayPickerCollectionView
{
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:7 inSection:0]
                                atScrollPosition:UICollectionViewScrollPositionLeft
                                        animated:NO];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.shouldUpdateDayPickerOffesetAfterScrollviewDelegateCallback) {
        [self updateDayPickerOffsetForInfiniteScrolling];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (self.shouldUpdateDayPickerOffesetAfterScrollviewDelegateCallback) {
        [self updateDayPickerOffsetForInfiniteScrolling];
    }
}

- (void)updateDayPickerOffsetForInfiniteScrolling
{
    if (self.collectionView.contentOffset.x <= 0 ) {
        self.currentlyDisplayedDate = [self.currentlyDisplayedDate dp_dateBySubtractingWeek];
    } else if (self.collectionView.contentOffset.x >= CGRectGetWidth(self.collectionView.bounds) * 2) {
        self.currentlyDisplayedDate = [self.currentlyDisplayedDate dp_dateByAddingWeek];
    }
}

- (void)animateDayPickerCollectionViewBackwards
{
    self.shouldUpdateDayPickerOffesetAfterScrollviewDelegateCallback = NO;
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
    [self performSelector:@selector(delayedCenterDayPickerCollectionView) withObject:nil afterDelay:0.3];
}

- (void)animateDayPickerCollectionViewForward
{
    self.shouldUpdateDayPickerOffesetAfterScrollviewDelegateCallback = NO;
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:14 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
    [self performSelector:@selector(delayedCenterDayPickerCollectionView) withObject:nil afterDelay:0.3];
}

- (void)delayedCenterDayPickerCollectionView
{
    [self updateDatesArray];
    [self reloadDayPicker];
    [self centerDayPickerCollectionView];
    self.shouldUpdateDayPickerOffesetAfterScrollviewDelegateCallback = YES;
}

#pragma mark - Dates Array

- (void)updateDatesArray
{
    NSMutableArray *newDatesArray = [[NSMutableArray alloc] init];
    
    NSDate *lastWeek = [self.currentlyDisplayedDate dp_dateBySubtractingWeek];
    NSDate *nextWeek = [self.currentlyDisplayedDate dp_dateByAddingWeek];
    
    [newDatesArray addObjectsFromArray:[lastWeek dp_datesInWeek]];
    [newDatesArray addObjectsFromArray:[self.currentlyDisplayedDate dp_datesInWeek]];
    [newDatesArray addObjectsFromArray:[nextWeek dp_datesInWeek]];
    
    self.datesArray = newDatesArray;
}

#pragma mark - Getters | Setters

- (void)setCurrentlyDisplayedDate:(NSDate *)currentlyDisplayedDate
{
    if ((!_currentlyDisplayedDate || ![currentlyDisplayedDate dp_isEqualToDateIgnoringTime:_currentlyDisplayedDate]) && currentlyDisplayedDate) {
        if ([currentlyDisplayedDate dp_dateFallsBetweenStartDate:self.datesArray[0] endDate:self.datesArray[6]]) {
            [self animateDayPickerCollectionViewBackwards];
        } else if ([currentlyDisplayedDate dp_dateFallsBetweenStartDate:self.datesArray[14] endDate:self.datesArray[20]]) {
            [self animateDayPickerCollectionViewForward];
        }
        NSDate *oldDate = _currentlyDisplayedDate;
        NSDate *newDate = currentlyDisplayedDate;
        _currentlyDisplayedDate = currentlyDisplayedDate;
        [self updateDatesArray];
        [self reloadDayPicker];
        if ([self.delegate respondsToSelector:@selector(dayPickerViewController:dateDidUpdateToDate:fromOldDate:)]) {
            [self.delegate dayPickerViewController:self dateDidUpdateToDate:newDate fromOldDate:oldDate];
        }
    }
}

- (NSDate *)currentlyDisplayedDate
{
    if (!_currentlyDisplayedDate) {
        _currentlyDisplayedDate = [[NSDate date] dp_startOfDay];
    }
    return _currentlyDisplayedDate;
}
@end
