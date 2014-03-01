#import "DiningHallMenuCompareView.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "DiningHallMenuCompareLayout.h"
#import "DiningHallMenuComparisonSectionHeaderView.h"

@interface DiningHallMenuCompareView () <UICollectionViewDataSource, CollectionViewDelegateMenuCompareLayout>

@property (nonatomic, strong) UILabel * headerView;
@property (nonatomic, strong) UICollectionView * collectionView;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

#define HEADER_VIEW_HEIGHT 24
#define DEFAULT_COLUMN_WIDTH 170
static NSString * const SectionHeaderIdentifier = @"DiningHallSectionHeader";

@implementation DiningHallMenuCompareView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.headerView = [[UILabel alloc] initWithFrame:CGRectZero];
        self.headerView.textAlignment = NSTextAlignmentCenter;
        self.headerView.textColor = [UIColor whiteColor];
        self.headerView.font = [UIFont boldSystemFontOfSize:12];
        self.headerView.backgroundColor = [UIColor colorWithHexString:@"#a41f35"];
        
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"MMMM dd"];
        
        DiningHallMenuCompareLayout *layout = [[DiningHallMenuCompareLayout alloc] init];
        
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        self.columnWidth = DEFAULT_COLUMN_WIDTH;
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        self.collectionView.directionalLockEnabled = YES;
        self.collectionView.showsHorizontalScrollIndicator = YES;
        self.collectionView.showsVerticalScrollIndicator = NO;
        self.collectionView.bounces = YES;
        self.collectionView.alwaysBounceVertical = YES;
        self.collectionView.alwaysBounceHorizontal = NO;
        self.collectionView.backgroundColor = [UIColor whiteColor];
        [self.collectionView registerClass:[DiningHallMenuComparisonCell class] forCellWithReuseIdentifier:@"DiningMenuCell"];                  // may want a delegate method or some way to register classes outside ComparisonView
        [self.collectionView registerClass:[DiningHallMenuComparisonNoMealsCell class] forCellWithReuseIdentifier:@"DiningMenuNoMealsCell"];
        [self.collectionView registerClass:[DiningHallMenuComparisonSectionHeaderView class] forSupplementaryViewOfKind:MITDiningMenuComparisonSectionHeaderKind withReuseIdentifier:SectionHeaderIdentifier];
        
        [self addSubview:self.headerView];
        [self addSubview:self.collectionView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect bounds = self.bounds;

    CGRect headerViewFrame = CGRectZero;
    CGRect collectionViewFrame = CGRectZero;
    CGRectDivide(bounds, &headerViewFrame, &collectionViewFrame, HEADER_VIEW_HEIGHT, CGRectMinYEdge);

    self.headerView.frame = headerViewFrame;
    self.collectionView.frame = collectionViewFrame;
}

- (void) setColumnWidth:(CGFloat)columnWidth
{
    _columnWidth = columnWidth;
    ((DiningHallMenuCompareLayout *)self.collectionView.collectionViewLayout).columnWidth = columnWidth;
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void) resetScrollOffset
{
    [self.collectionView setContentOffset:CGPointZero animated:NO];
}

- (void) setScrollOffsetAgainstRightEdge
{
    [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentSize.width - CGRectGetWidth(self.collectionView.bounds), 0) animated:NO];
}

- (void) setScrollOffset:(CGPoint) offset animated:(BOOL)animated
{
    [self.collectionView setContentOffset:offset animated:animated];
}

- (CGPoint) contentOffset
{
    return self.collectionView.contentOffset;
}

- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath
{
    return [self.collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
}

#pragma mark - UICollectionViewDatasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [self.delegate numberOfSectionsInCompareView:self];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.delegate compareView:self numberOfItemsInSection:section];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    DiningHallMenuComparisonSectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:SectionHeaderIdentifier forIndexPath:indexPath];
    headerView.titleLabel.text = [self.delegate compareView:self titleForSection:indexPath.section];
    headerView.timeLabel.text = [self.delegate compareView:self subtitleForSection:indexPath.section];
    
    return headerView;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.delegate compareView:self cellForRowAtIndexPath:indexPath];
}

#pragma mark - Data Source Helpers
- (void) reloadData
{
    self.headerView.text = [self.delegate titleForCompareView:self];
    [self.collectionView reloadData];
}


#pragma mark - CollectionViewDelegateMenuCompareLayout
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout heightForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.delegate compareView:self heightForRowAtIndexPath:indexPath];
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    // necessary for sticky headers. 
    [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark - UIScrollViewDelegate methods
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.isScrolling = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(compareViewDidEndDecelerating:)]) {
        [self.delegate compareViewDidEndDecelerating:self];
    }
    self.isScrolling = NO;
}

#pragma mark Class Methods
+ (NSString *) stringForMeal:(NSString *)mealName onDate:(NSDate *)date
{
    // Formats string for compareView Header
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    NSString *dayString;
    if ([date isToday]) {
        dayString = @"Today";
    } else if ([date isTomorrow]) {
        dayString = @"Tomorrow";
    } else if ([date isYesterday]) {
        dayString = @"Yesterday";
    } else {
        [dateFormatter setDateFormat:@"EEEE"];
        dayString = [dateFormatter stringFromDate:date];
    }
    
    [dateFormatter setDateFormat:@"MMM d"];
    NSString *fullDate = [dateFormatter stringFromDate:date];
    
    if (mealName && ![mealName isEqualToString:MealReferenceEmptyMeal]) {
        NSString * mealString = [mealName capitalizedString];
        return [NSString stringWithFormat:@"%@'s %@, %@", dayString, mealString, fullDate];
    } else {
        return [NSString stringWithFormat:@"%@, %@", dayString, fullDate];
    }
}


@end
