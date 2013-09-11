#import "MITScrollingNavigationBar.h"

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
        self.backgroundColor = [UIColor whiteColor];

        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:frame
                                                              collectionViewLayout:layout];
        collectionView.allowsMultipleSelection = NO;
        collectionView.allowsSelection = YES;
        collectionView.backgroundView.backgroundColor = [UIColor clearColor];
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
             UITextAttributeTextColor : [UIColor whiteColor]};
}

- (NSDictionary*)textAttributesForHighlightedTitle
{
    return @{UITextAttributeFont : [UIFont boldSystemFontOfSize:[UIFont labelFontSize]],
             UITextAttributeTextColor : [UIColor lightGrayColor]};
}

- (NSDictionary*)textAttributesForTitle
{
    return @{UITextAttributeFont : [UIFont systemFontOfSize:[UIFont labelFontSize]],
             UITextAttributeTextColor : [UIColor whiteColor]};
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
    NSIndexPath *selectedIndexPath = [[collectionView indexPathsForSelectedItems] lastObject];
    NSDictionary *textAttributes = nil;
    if ([indexPath isEqual:selectedIndexPath]) {
        textAttributes = [self textAttributesForSelectedTitle];
    } else {
        textAttributes = [self textAttributesForTitle];
    }

    NSString *title = [self.dataSource navigationBar:self
                             titleForItemAtIndexPath:indexPath];
    return [title sizeWithFont:textAttributes[UITextAttributeFont]
                      forWidth:CGFLOAT_MAX
                 lineBreakMode:NSLineBreakByClipping];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    UIImage *searchIcon = [UIImage imageNamed:@"global/search"];
    return [searchIcon size];
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
            [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[searchButton]|"
                                                                           options:0
                                                                           metrics:0
                                                                           views:views]];
            [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[searchButton]|"
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

    NSDictionary *textAttributes = nil;
    if (cell.isSelected) {
        textAttributes = [self textAttributesForSelectedTitle];
    } else {
        textAttributes = [self textAttributesForTitle];
    }

    titleLabel.font = textAttributes[UITextAttributeFont];
    titleLabel.textColor = textAttributes[UITextAttributeTextColor];
    titleLabel.highlightedTextColor = [UIColor lightGrayColor];
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

    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

@end
