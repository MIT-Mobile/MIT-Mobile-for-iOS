#import <Foundation/Foundation.h>

@interface MITCollectionViewGridLayoutRow : NSObject
@property (nonatomic) CGFloat interItemSpacing;

// Only the width is used. The height is ignored for layout purposes.
@property (nonatomic) CGRect frame;
@property (nonatomic,readonly) CGRect bounds;
@property (nonatomic,readonly) NSUInteger numberOfItems;
@property (nonatomic,readonly) NSArray *itemLayoutAttributes;
@property (nonatomic,readonly) NSArray *decorationLayoutAttributes;

- (instancetype)init;
- (void)addItemForIndexPath:(NSIndexPath*)indexPath withHeight:(CGFloat)itemHeight;
@end
