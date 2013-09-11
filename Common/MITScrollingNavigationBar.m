#import "MITScrollingNavigationBar.h"
#import "MITAdditions.h"

static NSString* const MITScrollingNavigationItemReuseIdentifier = @"MITScrollingNavigationItem";
static NSString* const MITScrollingNavigationSearchIconReuseIdentifier = @"MITScrollingNavigationSearchIcon";

typedef NS_ENUM(NSUInteger, MITScrollingNavigationItemTag) {
    MITScrollingNavigationItemTagLabel = 0xFAD0,
    MITScrollingNavigationItemTagIcon = 0xFAD1
};

@interface MITScrollingNavigationBar () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic,weak) UICollectionView *collectionView;
@end

@implementation MITScrollingNavigationBar
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.sectionInset = UIEdgeInsetsMake(0, 8, 0, 20.);
        layout.minimumInteritemSpacing = 16.;
        layout.minimumLineSpacing = 21.; // Roughly one line of text

        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:frame
                                                              collectionViewLayout:layout];
        collectionView.allowsMultipleSelection = NO;
        collectionView.allowsSelection = YES;
        collectionView.backgroundColor = [UIColor colorWithRed:0.6
                                                         green:0.2
                                                          blue:0.2
                                                         alpha:1.0];
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.bounces = YES;
        collectionView.alwaysBounceHorizontal = NO;
        collectionView.dataSource = self;
        collectionView.delegate = self;
        collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        [collectionView registerClass:[UICollectionViewCell class]
           forCellWithReuseIdentifier:MITScrollingNavigationItemReuseIdentifier];

        [collectionView registerClass:[UICollectionReusableView class]
           forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                  withReuseIdentifier:MITScrollingNavigationSearchIconReuseIdentifier];

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

- (NSDictionary*)textAttributesForSelectedTitle
{
    return @{UITextAttributeFont : [UIFont boldSystemFontOfSize:[UIFont labelFontSize]],
             UITextAttributeTextColor : [UIColor redColor]};
}

- (NSDictionary*)textAttributesForTitle
{
    return @{UITextAttributeFont : [UIFont boldSystemFontOfSize:[UIFont labelFontSize]],
             UITextAttributeTextColor : [UIColor blackColor]};
}

- (IBAction)searchButtonWasTapped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(didSelectSearchItemInNavigationBar:)]) {
        [self.delegate didSelectSearchItemInNavigationBar:self];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *textAttributes = [self textAttributesForTitle];

    NSString *title = [self.dataSource navigationBar:self
                             titleForItemAtIndexPath:indexPath];


    CGSize cellSize = [title sizeWithFont:textAttributes[UITextAttributeFont]
                                 forWidth:CGFLOAT_MAX
                            lineBreakMode:NSLineBreakByClipping];
    cellSize.width += 8.;
    cellSize.height += 4.;
    return cellSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    BOOL shouldShowSearchIcon = NO;
    if ([self.delegate respondsToSelector:@selector(shouldShowSearchItemInNavigationBar:)]) {
        shouldShowSearchIcon = [self.delegate shouldShowSearchItemInNavigationBar:self];
    }

    if (shouldShowSearchIcon) {
        return CGSizeMake(CGRectGetHeight(collectionView.bounds), CGRectGetHeight(collectionView.bounds));
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
                                                                              withReuseIdentifier:MITScrollingNavigationSearchIconReuseIdentifier
                                                                                     forIndexPath:indexPath];
        UIButton *searchButton = (UIButton*)[header viewWithTag:MITScrollingNavigationItemTagIcon];
        if (!searchButton) {
            searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
            searchButton.tag = MITScrollingNavigationItemTagIcon;
            searchButton.translatesAutoresizingMaskIntoConstraints = NO;

            [searchButton setImage:[UIImage imageNamed:@"global/search"]
                          forState:UIControlStateNormal];
            [searchButton addTarget:self
                             action:@selector(searchButtonWasTapped:)
                   forControlEvents:UIControlEventTouchUpInside];

            [header addSubview:searchButton];

            NSDictionary *views = @{@"searchButton" : searchButton};
            [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[searchButton(>=0)]|"
                                                                           options:0
                                                                           metrics:0
                                                                           views:views]];
            [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[searchButton(>=0)]|"
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
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MITScrollingNavigationItemReuseIdentifier
                                                                           forIndexPath:indexPath];
    cell.layer.cornerRadius = 8.;

    UILabel *titleLabel = (UILabel*)[cell viewWithTag:MITScrollingNavigationItemTagLabel];
    if (!titleLabel) {
        titleLabel = [[UILabel alloc] init];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.tag = MITScrollingNavigationItemTagLabel;

        [cell addSubview:titleLabel];
        [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[title]|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:@{@"title" : titleLabel}]];
        [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[title]|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:@{@"title" : titleLabel}]];
    }

    NSDictionary *textAttributes = [self textAttributesForTitle];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = textAttributes[UITextAttributeFont];
    titleLabel.textColor = textAttributes[UITextAttributeTextColor];
    titleLabel.highlightedTextColor = [UIColor whiteColor];
    titleLabel.text = [self.dataSource navigationBar:self
                             titleForItemAtIndexPath:indexPath];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(navigationBar:didSelectItemAtIndexPath:)]) {
        [self.delegate navigationBar:self
            didSelectItemAtIndexPath:indexPath];
    }

    [collectionView selectItemAtIndexPath:indexPath
                                 animated:YES
                           scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithWhite:0.25
                                             alpha:0.25];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];

    cell.backgroundColor = [UIColor clearColor];
}

@end
