#import "MITScrollingNavigationBar.h"
#import "MITScrollingNavigationBarCell.h"
#import "MITAdditions.h"

static NSString* const MITScrollingNavigationItemReuseIdentifier = @"MITScrollingNavigationItem";
static NSString* const MITScrollingNavigationAccessoryReuseIdentifier = @"MITScrollingNavigationAccessory";

typedef NS_ENUM(NSUInteger, MITScrollingNavigationItemTag) {
    MITScrollingNavigationItemTagAccessory = 0xFAD1
};

@interface MITScrollingNavigationBar () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic,weak) UICollectionView *collectionView;
@end

@implementation MITScrollingNavigationBar
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.6
                                               green:0.2
                                                blue:0.2
                                               alpha:1.0];

        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.sectionInset = UIEdgeInsetsMake(0, 8, 0, 20.);
        layout.minimumInteritemSpacing = 16.;
        layout.minimumLineSpacing = 21.; // Roughly one line of text

        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:frame
                                                              collectionViewLayout:layout];
        collectionView.allowsMultipleSelection = NO;
        collectionView.allowsSelection = YES;
        collectionView.backgroundColor = [UIColor clearColor];
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.bounces = YES;
        collectionView.alwaysBounceHorizontal = NO;
        collectionView.dataSource = self;
        collectionView.delegate = self;
        collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        [collectionView registerClass:[MITScrollingNavigationBarCell class]
           forCellWithReuseIdentifier:MITScrollingNavigationItemReuseIdentifier];

        [collectionView registerClass:[UICollectionReusableView class]
           forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                  withReuseIdentifier:MITScrollingNavigationAccessoryReuseIdentifier];

        [self addSubview:collectionView];

        NSDictionary *views = @{@"collectionView" : collectionView};

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[collectionView]|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView]|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];

        _selectedIndex = 0;
    }

    return self;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    if (_selectedIndex != selectedIndex) {
        _selectedIndex = selectedIndex;

        if (_selectedIndex != NSNotFound) {
            [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:_selectedIndex inSection:0]
                                              animated:YES
                                        scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        }
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // The selected text may be larger so use the selected format
    // for sizing the cell so we don't have to resize things once
    // the selection starts changing
    NSDictionary *textAttributes = [MITScrollingNavigationBarCell textAttributesForSelectedTitle];

    NSString *title = [self.dataSource navigationBar:self
                                 titleForItemAtIndex:indexPath.item];

    CGSize cellSize = [title sizeWithFont:textAttributes[UITextAttributeFont]
                                 forWidth:CGFLOAT_MAX
                            lineBreakMode:NSLineBreakByClipping];
    cellSize.width += 8.;
    cellSize.height += 4.;
    return cellSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    CGFloat accessoryWidth = CGFLOAT_MIN;
    if ([self.delegate respondsToSelector:@selector(widthForAccessoryViewInNavigationBar:)]) {
        accessoryWidth = [self.delegate widthForAccessoryViewInNavigationBar:self];
    }

    if (accessoryWidth >= 1.) {
        return CGSizeMake(accessoryWidth, CGRectGetHeight(collectionView.bounds));
    } else {
        return CGSizeZero;
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.dataSource numberOfItemsInNavigationBar:self];
}

- (UICollectionReusableView*)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                              withReuseIdentifier:MITScrollingNavigationAccessoryReuseIdentifier
                                                                                     forIndexPath:indexPath];
        if (![header viewWithTag:MITScrollingNavigationItemTagAccessory]) {
            UIView *accessoryView = nil;
            if ([self.delegate respondsToSelector:@selector(accessoryViewForNavigationBar:)]) {
                accessoryView = [self.delegate accessoryViewForNavigationBar:self];
            }

            [header addSubview:accessoryView];
            accessoryView.translatesAutoresizingMaskIntoConstraints = NO;

            NSDictionary *views = @{@"accessoryView" : accessoryView};
            [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[accessoryView(>=0)]|"
                                                                           options:0
                                                                           metrics:0
                                                                             views:views]];
            [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[accessoryView(>=0)]|"
                                                                           options:0
                                                                           metrics:0
                                                                             views:views]];
        }

        return header;
    } else {
        return nil;
    }
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MITScrollingNavigationBarCell *cell = (MITScrollingNavigationBarCell*)[collectionView dequeueReusableCellWithReuseIdentifier:MITScrollingNavigationItemReuseIdentifier
                                                                           forIndexPath:indexPath];
    
    if (_selectedIndex == indexPath.item) {
        cell.selected = YES;
        [collectionView selectItemAtIndexPath:indexPath
                                     animated:NO
                               scrollPosition:UICollectionViewScrollPositionNone];
    }

    cell.titleLabel.text = [self.dataSource navigationBar:self
                                      titleForItemAtIndex:indexPath.item];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedIndex = NSNotFound;
    [collectionView deselectItemAtIndexPath:indexPath
                                   animated:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_selectedIndex != indexPath.item) {
        _selectedIndex = indexPath.item;

        [collectionView selectItemAtIndexPath:indexPath
                                     animated:YES
                               scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];

        if ([self.delegate respondsToSelector:@selector(navigationBar:didSelectItemAtIndex:)]) {
            [self.delegate navigationBar:self
                    didSelectItemAtIndex:indexPath.item];
        }
    }
}

@end

