#import <Foundation/Foundation.h>

@interface MITCollectionViewGridLayoutRow : NSObject
@property (nonatomic) NSUInteger numberOfItems;

@property (nonatomic) CGPoint origin;
@property (nonatomic,readonly) CGSize contentSize;
@property (nonatomic,readonly) CGRect contentFrame;

@property (nonatomic,readonly) NSArray *itemLayoutAttributes;
@property (nonatomic,readonly) NSArray *decorationLayoutAttributes;

+ (instancetype)rowWithNumberOfItems:(NSUInteger)numberOfItems minimumInterItemPadding:(CGFloat)interItemPadding;

- (BOOL)canAcceptItems;
- (CGSize)contentSize;

- (BOOL)addItemForIndexPath:(NSIndexPath*)path itemSize:(CGSize)size;
- (NSArray*)layoutAttributesInRect:(CGRect)rect;
@end
