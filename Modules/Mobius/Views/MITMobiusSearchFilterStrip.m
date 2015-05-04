#import "MITMobiusSearchFilterStrip.h"
#import "MITMobiusSearchFilterStripCell.h"

static NSString * const MITMobiusSearchFilterStripCellIdentifier = @"MITMobiusSearchFilterStripCellIdentifier";

@interface MITMobiusSearchFilterStrip () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) NSInteger numberOfFilters;
@property (nonatomic, strong) NSArray *textForFilters;

@end

@implementation MITMobiusSearchFilterStrip
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.minimumInteritemSpacing = 0.0;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = [UIColor colorWithRed:(248.0/255.0) green:(248.0/255.0) blue:(248.0/255.0) alpha:1];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;

    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MITMobiusSearchFilterStripCell class]) bundle:nil] forCellWithReuseIdentifier:MITMobiusSearchFilterStripCellIdentifier];
    
    [self addSubview:self.collectionView];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[collectionView]-0-|" options:0 metrics:nil views:@{@"collectionView": self.collectionView}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[collectionView]-0-|" options:0 metrics:nil views:@{@"collectionView": self.collectionView}]];
    
    UIImage *rightGradientImage = [[UIImage imageNamed:MITImageMobiusFilterStripEndcapRight] resizableImageWithCapInsets:UIEdgeInsetsZero];
    UIImageView *rightGradientImageView = [[UIImageView alloc] initWithImage:rightGradientImage];
    rightGradientImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:rightGradientImageView];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[rightGraident(==16)]-0-|" options:0 metrics:nil views:@{@"rightGraident": rightGradientImageView}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[rightGraident]-0-|" options:0 metrics:nil views:@{@"rightGraident": rightGradientImageView}]];
    
    // Flip the image 180 degrees to make a left endcap
    CGSize imageSize = rightGradientImage.size;
    UIGraphicsBeginImageContext(imageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, imageSize.width/2, imageSize.height/2);
    CGContextRotateCTM(context, M_PI);
    
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGRectMake(-imageSize.width / 2, -imageSize.height / 2, imageSize.width, imageSize.height), [rightGradientImage CGImage]);
    
    UIImage *leftGradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *leftGradientImageView = [[UIImageView alloc] initWithImage:[leftGradientImage resizableImageWithCapInsets:UIEdgeInsetsZero]];
    leftGradientImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:leftGradientImageView];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[leftGraident(==16)]" options:0 metrics:nil views:@{@"leftGraident": leftGradientImageView}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[leftGraident]-0-|" options:0 metrics:nil views:@{@"leftGraident": leftGradientImageView}]];
}

#pragma mark Public Methods

- (void)reloadData
{
    if ([self.dataSource respondsToSelector:@selector(numberOfFiltersForStrip:)]) {
        self.numberOfFilters = [self.dataSource numberOfFiltersForStrip:self];
    } else {
        self.numberOfFilters = 0;
    }
    
    if ([self.dataSource respondsToSelector:@selector(searchFilterStrip:textForFilterAtIndex:)]) {
        NSMutableArray *newFilterTexts = [NSMutableArray array];
        
        for (NSInteger i = 0; i < self.numberOfFilters; i++) {
            [newFilterTexts addObject:[self.dataSource searchFilterStrip:self textForFilterAtIndex:i]];
        }
        
        self.textForFilters = [NSArray arrayWithArray:newFilterTexts];
    } else {
        self.textForFilters = nil;
    }
    
    [self.collectionView reloadData];
}

#pragma mark UICollectionViewDataSource Methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.numberOfFilters;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MITMobiusSearchFilterStripCell *textCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:MITMobiusSearchFilterStripCellIdentifier forIndexPath:indexPath];
    
    [textCell setText:self.textForFilters[indexPath.row]];
    
    return textCell;
}

#pragma mark UICollectionViewDelegateFlowLayout Methods

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MITMobiusSearchFilterStripCell *cell = [MITMobiusSearchFilterStripCell sizingCell];
    [cell setText:self.textForFilters[indexPath.row]];
    CGSize compressedSize = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGSize cellSize = CGSizeMake(compressedSize.width, self.collectionView.bounds.size.height);
    return cellSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 16, 0, 16);
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(searchFilterStrip:didSelectFilterAtIndex:)]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(searchFilterStrip:didSelectFilterAtIndex:)]) {
        [self.delegate searchFilterStrip:self didSelectFilterAtIndex:indexPath.row];
    }
}

@end
