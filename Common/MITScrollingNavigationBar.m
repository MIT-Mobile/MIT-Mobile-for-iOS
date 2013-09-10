#import "MITScrollingNavigationBar.h"

@interface MITScrollingNavigationBar () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic,weak) UICollectionView *collectionView;
@end

@implementation MITScrollingNavigationBar
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:frame
                                                              collectionViewLayout:layout];
        [self addSubview:collectionView];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[collectionView]|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:@{@"collectionView" : collectionView}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView]|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:@{@"collectionView" : collectionView}]];
                                                                               
    }
    return self;
}


#pragma mark - UICollectionViewDelegate


#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.dataSource numberOfItemsInNavigationBar:self];
}



@end
