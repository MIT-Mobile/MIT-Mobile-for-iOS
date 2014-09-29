#import "MITCollectionViewCellSizer.h"
@interface MITCollectionViewCellSizer ()
- (void)setLayoutCell:(UICollectionViewCell*)layoutCell forReuseIdentifier:(NSString*)reuseIdentifier;
- (UICollectionViewCell*)layoutCellForReuseIdentifier:(NSString*)reuseIdentifier;
@end

@implementation MITCollectionViewCellSizer
{
    NSMutableDictionary* _calculatedCellHeights;
    NSMutableDictionary* _layoutCollectionViewCells;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _calculatedCellHeights = [[NSMutableDictionary alloc] init];
        _layoutCollectionViewCells = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}


- (void)setLayoutCell:(UICollectionViewCell*)layoutCell forReuseIdentifier:(NSString*)reuseIdentifier
{
    NSAssert(reuseIdentifier, @"layout cell must have a valid reuse identifier");
    
    if (layoutCell) {
        _layoutCollectionViewCells[reuseIdentifier] = layoutCell;
    } else {
        [_layoutCollectionViewCells removeObjectForKey:reuseIdentifier];
    }
}

- (UICollectionViewCell*)layoutCellForReuseIdentifier:(NSString*)reuseIdentifier
{
    UICollectionViewCell *cell = _layoutCollectionViewCells[reuseIdentifier];
    
    return cell;
}

- (void)registerClass:(Class)cellClass forLayoutCellWithReuseIdentifier:(NSString *)reuseIdentifier
{
    NSParameterAssert(reuseIdentifier);
    
    if (cellClass) {
        NSAssert([cellClass isSubclassOfClass:[UICollectionViewCell class]], @"cell class must be a subclass of UICollectionViewCell");
        
        UICollectionViewCell *cell = [[cellClass alloc] init];
        [self setLayoutCell:cell forReuseIdentifier:reuseIdentifier];
    } else {
        [self setLayoutCell:nil forReuseIdentifier:reuseIdentifier];
    }
}

- (void)registerNib:(UINib *)nib forLayoutCellWithReuseIdentifier:(NSString *)reuseIdentifier
{
    NSParameterAssert(reuseIdentifier);
    
    if (!nib) {
        [self setLayoutCell:nil forReuseIdentifier:reuseIdentifier];
    } else {
        UICollectionViewCell *cell = [[nib instantiateWithOwner:nil options:nil] firstObject];
        NSAssert([cell isKindOfClass:[UICollectionViewCell class]],@"root object [%@] must be type of UICollectionView",cell);
        
        [self setLayoutCell:cell forReuseIdentifier:reuseIdentifier];
    }
}

- (CGSize)sizeForCellWithReuseIdentifier:(NSString*)reuseIdentifier atIndexPath:(NSIndexPath*)indexPath withSize:(CGSize)size flexibleAxis:(MITFlexibleAxis)flexibleAxis
{
    if (MITFlexibleAxisHorizontal == flexibleAxis) {
        size.width = 0;
    } else if (MITFlexibleAxisVertical == flexibleAxis) {
        size.height = 0;
    }
    
    if (!self.delegate) {
        return size;
    } else if (![self.delegate conformsToProtocol:@protocol(MITCollectionViewCellAutosizing)]) {
        DDLogWarn(@"%@ does not conform to protocol MITUICollectionViewDynamicSizing, returning CGSizeZero",NSStringFromClass([self.delegate class]));
        return size;
    }
    
    UICollectionViewCell *layoutCell = [self layoutCellForReuseIdentifier:reuseIdentifier];
    
    if (!layoutCell) {
        return size;
    }
    
    NSMutableArray *cellConstraints = [[NSMutableArray alloc] init];
    CGRect frame = layoutCell.frame;
    UIView *targetView = nil;
    
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) {
        targetView = layoutCell;
    } else{
        targetView = layoutCell.contentView;
    }
    
    if ((MITFlexibleAxisNone == flexibleAxis) || (MITFlexibleAxisHorizontal == flexibleAxis)) {
        [cellConstraints addObject:[NSLayoutConstraint constraintWithItem:targetView attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.
                                                                 constant:size.height]];
        frame.size.height = size.height;
    }
    
    if ((MITFlexibleAxisNone == flexibleAxis) || (MITFlexibleAxisVertical == flexibleAxis)) {
        [cellConstraints addObject:[NSLayoutConstraint constraintWithItem:targetView attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.
                                                                 constant:size.width]];
        frame.size.width = size.width;
    }
    
    layoutCell.frame = frame;
    layoutCell.contentView.frame = layoutCell.bounds;
    [targetView addConstraints:cellConstraints];
    
    // Let this re-layout to account for the updated width
    // (such as re-positioning the content view)
    [layoutCell setNeedsLayout];
    [layoutCell layoutIfNeeded];
    
    [layoutCell prepareForReuse];
    
    [self.delegate collectionViewCellSizer:self configureContentForLayoutCell:layoutCell withReuseIdentifier:reuseIdentifier atIndexPath:indexPath];
    
    // Now that the view has been laid out for the proper width
    // give it a chance to update any constraints which need tweaking
    [layoutCell setNeedsUpdateConstraints];
    [layoutCell updateConstraintsIfNeeded];
    
    // ...and then relayout again!
    [layoutCell setNeedsLayout];
    [layoutCell layoutIfNeeded];
    
    CGSize fittingSize = [targetView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    [targetView removeConstraints:cellConstraints];
    
    switch (flexibleAxis) {
        case MITFlexibleAxisVertical: {
            fittingSize.width = size.width;
        } break;
            
        case MITFlexibleAxisHorizontal: {
            fittingSize.height = size.height;
        } break;
            
        default:
            break;
    }
    
    return fittingSize;
}

@end
