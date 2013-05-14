#import <Foundation/Foundation.h>
#import "DiningHallMenuCompareView.h"
#import "PSTCollectionView.h"
#import "UIKit+MITAdditions.h"
#import "DiningHallMenuCompareLayout.h"
#import "DiningHallMenuComparisonSectionHeaderView.h"

@interface DiningHallMenuCompareView () <PSTCollectionViewDataSource, CollectionViewDelegateMenuCompareLayout>

@property (nonatomic, strong) UILabel * headerView;
@property (nonatomic, strong) PSTCollectionView * collectionView;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

#define HEADER_VIEW_HEIGHT 24
#define DEFAULT_COLUMN_WIDTH 180
static NSString * const SectionHeaderIdentifier = @"DiningHallSectionHeader";

@implementation DiningHallMenuCompareView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.headerView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, HEADER_VIEW_HEIGHT)];
        self.headerView.textAlignment = UITextAlignmentCenter;
        self.headerView.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
        
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"MMMM dd"];
        
        DiningHallMenuCompareLayout *layout = [[DiningHallMenuCompareLayout alloc] init];
        
        CGFloat headerHeight = CGRectGetHeight(self.headerView.frame);
        self.collectionView = [[PSTCollectionView alloc] initWithFrame:CGRectMake(0, headerHeight, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - headerHeight) collectionViewLayout:layout];
        self.columnWidth = DEFAULT_COLUMN_WIDTH;
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        self.collectionView.directionalLockEnabled = YES;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.showsVerticalScrollIndicator = NO;
        [self.collectionView registerClass:[DiningHallMenuComparisonCell class] forCellWithReuseIdentifier:@"DiningMenuCell"];
        [self.collectionView registerClass:[DiningHallMenuComparisonSectionHeaderView class] forSupplementaryViewOfKind:MITDiningMenuComparisonSectionHeaderKind withReuseIdentifier:SectionHeaderIdentifier];
        
        [self addSubview:self.headerView];
        [self addSubview:self.collectionView];
    }
    return self;
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

- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath
{
    return [self.collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
}

#pragma mark - PSTCollectionViewDatasource

- (NSInteger)numberOfSectionsInCollectionView:(PSTCollectionView *)collectionView
{
    return [self.delegate numberOfSectionsInCompareView:self];
}

- (NSInteger)collectionView:(PSTCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.delegate compareView:self numberOfItemsInSection:section];
}

- (PSTCollectionReusableView *)collectionView:(PSTCollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    DiningHallMenuComparisonSectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:SectionHeaderIdentifier forIndexPath:indexPath];
    headerView.titleLabel.text = [self.delegate compareView:self titleForSection:indexPath.section];
    headerView.timeLabel.text = [self.delegate compareView:self subtitleForSection:indexPath.section];
    
    return headerView;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (PSTCollectionViewCell *)collectionView:(PSTCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
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
- (CGFloat)collectionView:(PSTCollectionView *)collectionView layout:(PSTCollectionViewLayout*)collectionViewLayout heightForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.delegate compareView:self heightForRowAtIndexPath:indexPath];
//    return [DiningHallMenuComparisonCell heightForComparisonCellOfWidth:COLUMN_WIDTH withPrimaryText:@"Old fashioned hamburgers and hotdogs" secondaryText:@"served with fries and shakes" numDietaryTypes:2];
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    // necessary for sticky headers. 
    [self.collectionView.collectionViewLayout invalidateLayout];
}


@end
