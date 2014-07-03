#import <Foundation/Foundation.h>

@interface MITCollectionViewGridLayoutRow : NSObject
@property (nonatomic) CGFloat interItemSpacing;

// Only the width is used. The height is ignored for layout purposes.
@property (nonatomic) CGRect frame;
@property (nonatomic) CGRect bounds;
@property (nonatomic) NSUInteger maximumNumberOfItems;

@property (nonatomic,readonly) NSUInteger numberOfItems;
@property (nonatomic,readonly) NSArray *itemLayoutAttributes;
@property (nonatomic,readonly) NSArray *decorationLayoutAttributes;

- (instancetype)init;
- (BOOL)addItemForIndexPath:(NSIndexPath*)indexPath withHeight:(CGFloat)itemHeight;
@end
