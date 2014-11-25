#import <Foundation/Foundation.h>

@interface MITCollectionViewGridLayoutRow : NSObject
@property (nonatomic) CGFloat interItemPadding;
@property (nonatomic) CGFloat columnWidth;

// Only the width is used. The height is ignored for layout purposes.
@property (nonatomic) CGPoint origin;
@property (nonatomic,readonly) CGRect frame;
@property (nonatomic,readonly) CGRect bounds;
@property (nonatomic) NSUInteger maximumNumberOfItems;

@property (nonatomic,readonly) BOOL isFilled;
@property (nonatomic,readonly) NSUInteger numberOfItems;
@property (nonatomic,readonly) NSArray *itemLayoutAttributes;


- (instancetype)init;
- (BOOL)addItemForIndexPath:(NSIndexPath*)indexPath;
- (void)setHeight:(CGFloat)height forItemWithIndexPath:(NSIndexPath*)indexPath;
@end
