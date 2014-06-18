#import <Foundation/Foundation.h>

@interface MITCollectionViewGridLayoutRow : NSObject
@property (nonatomic,readonly) NSUInteger maximumNumberOfItems;
@property (nonatomic,readonly) NSUInteger numberOfItems;

@property (nonatomic) CGPoint origin;
@property (nonatomic,readonly) CGSize contentSize;
@property (nonatomic,readonly) CGRect contentFrame;

@property (nonatomic,readonly) NSArray *itemLayoutAttributes;
@property (nonatomic,readonly) NSArray *decorationLayoutAttributes;

+ (instancetype)rowWithMaximumNumberOfItems:(NSUInteger)numberOfItems interItemSpacing:(CGFloat)interItemSpacing;

- (BOOL)canAcceptItems;
- (CGSize)contentSize;

- (BOOL)addItemForIndexPath:(NSIndexPath*)path itemSize:(CGSize)size;
@end
