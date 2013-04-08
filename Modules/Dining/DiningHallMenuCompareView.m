//
//  DiningHallMenuCompareView.m
//  MIT Mobile
//
//  Created by Austin Emmons on 4/8/13.
//
//

#import "DiningHallMenuCompareView.h"
#import "PSTCollectionView.h"

@interface DiningHallMenuCompareView () <PSTCollectionViewDataSource, PSTCollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UILabel * headerView;
@property (nonatomic, strong) PSTCollectionView * collectionView;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

#define HEADER_VIEW_HEIGHT 24

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
        
        [self addSubview:self.headerView];
    }
    return self;
}

- (NSArray *) debugHouseDiningData
{
    return [NSArray arrayWithObjects:@"Baker", @"The Howard Dining Hall", @"McCormick", @"Next", @"Simmons", nil];
}

#pragma mark Setter Override

- (void) setDate:(NSDate *)date
{
    _date = date;
    self.headerView.text = [self.dateFormatter stringFromDate:self.date];
    // TODO :: should reload data for date
    
}


#pragma mark - PSTCollectionViewDatasource

- (NSInteger)numberOfSectionsInCollectionView:(PSTCollectionView *)collectionView
{
    return [[self debugHouseDiningData] count];
}

- (NSInteger)collectionView:(PSTCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 3;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (PSTCollectionViewCell *)collectionView:(PSTCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PSTCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell-reuse" forIndexPath:indexPath];
    if (!cell) {
        cell = [[PSTCollectionViewCell alloc] init];
    }
    cell.backgroundColor = [UIColor greenColor];
    
    return cell;
}


#pragma mark - PSTCollectionViewDelegateFlowLayout

- (CGSize)collectionView:(PSTCollectionView *)collectionView layout:(PSTCollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(120, 50);
}

- (UIEdgeInsets)collectionView:(PSTCollectionView *)collectionView layout:(PSTCollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)sectio{
    return UIEdgeInsetsMake(1, 1, 1, 1);
}

- (CGFloat)collectionView:(PSTCollectionView *)collectionView layout:(PSTCollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 2;
}

- (CGFloat)collectionView:(PSTCollectionView *)collectionView layout:(PSTCollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 1;
}

- (CGSize)collectionView:(PSTCollectionView *)collectionView layout:(PSTCollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeZero;
}

- (CGSize)collectionView:(PSTCollectionView *)collectionView layout:(PSTCollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    return CGSizeZero;
}

- (PSTCollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}


@end
