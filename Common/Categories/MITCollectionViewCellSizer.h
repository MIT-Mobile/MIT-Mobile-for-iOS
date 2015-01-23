#import <Foundation/Foundation.h>

@protocol MITCollectionViewCellAutosizing;

typedef NS_ENUM(NSUInteger, MITFlexibleAxis) {
    MITFlexibleAxisNone = 0,
    MITFlexibleAxisHorizontal,
    MITFlexibleAxisVertical
};

@interface MITCollectionViewCellSizer : NSObject
@property(nonatomic,weak) id<MITCollectionViewCellAutosizing> delegate;

- (instancetype)init;

/** Registers a UICollectionViewCell class for autosizing with the specified reuseIdentifier.
 *  If this method is called multiple times, the registed class will be replace with the most
 *  recent value.
 *
 * @param cellClass the class to register. Must be a subclass of UICollectionViewCell or nil
 * @param reuseIdentifier the reuse identifier to register
 */
- (void)registerClass:(Class)cellClass forLayoutCellWithReuseIdentifier:(NSString *)reuseIdentifier;

/** Registers a UICollectionViewCell nib for autosizing with the specified reuseIdentifier.
 *  If this method is called multiple times, the registed class will be replace with the most
 *  recent value.
 *
 * @param nib the nib to register. The top-level object must be a UICollectionViewCell or nil
 * @param reuseIdentifier  the reuse identifier to register
 */
- (void)registerNib:(UINib *)nib forLayoutCellWithReuseIdentifier:(NSString *)reuseIdentifier;

/**
 *  Calculates the minimum size required to meet the cell's autolayout constraints.
 *  Cell heights are not cached and will be calculated every time this method is called.
 *  If a layout cell has not been configured for a specific reuse identifier or the delegate
 *  does not conform to the MITCollectionViewCellAutosizing protocol, CGSizeZero will be returned.
 *
 *  @param reuseIdentifier the reuse identifier for the layout cell to be used
 *  @param indexPath the index path the layout cell's content should be configured for
 *  @param size the maximum size of the cell's layout frame.
 *  @param axis the direction in which the cell may be exceed the maximum size. A cell may have flexible width (size.width is ignored), flexible height (size.height is ignored) or the calculated size must be less than or equal to the input size.
 *  @return the size for the cell.
 *  @see mit_collectionView:configureContentForLayoutCell:withReuseIdentifier:atIndexPath:
 */
- (CGSize)sizeForCellWithReuseIdentifier:(NSString*)reuseIdentifier atIndexPath:(NSIndexPath*)indexPath withSize:(CGSize)size flexibleAxis:(MITFlexibleAxis)flexibleAxis;
@end

@protocol MITCollectionViewCellAutosizing <NSObject>
@required
/** Configures the content for the specified cell, reuse identifier and index path.
 *  Cells will only have dynamic sizing enabled if they were registed using the
 *  registerClass:forLayoutCellWithReuseIdentifier: and registerNib:forLayoutCellWithReuseIdentifier:
 *  methods.
 */
- (void)collectionViewCellSizer:(MITCollectionViewCellSizer*)collectionViewCellSizer configureContentForLayoutCell:(UICollectionViewCell*)cell withReuseIdentifier:(NSString*)reuseIdentifier atIndexPath:(NSIndexPath*)indexPath;
@end
