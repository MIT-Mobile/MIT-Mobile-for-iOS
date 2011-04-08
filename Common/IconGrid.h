#import <UIKit/UIKit.h>

@protocol IconGridDelegate;

@interface IconGrid : UIView {
	id<IconGridDelegate> delegate;
	
    NSArray *icons;
}

@property (nonatomic, assign) id<IconGridDelegate> delegate;

@property (nonatomic, retain) NSArray *icons;

// Margin == distance between container perimeter and its icons
// Padding == distance between any two icons

@property CGFloat horizontalMargin;
@property CGFloat verticalMargin;
@property CGFloat horizontalPadding; // horizontal padding is really just a lower bound on padding
@property CGFloat verticalPadding;
@property NSInteger minColumns;
@property NSInteger maxColumns;

- (void)setHorizontalMargin:(CGFloat)hMargin vertical:(CGFloat)vMargin;
- (void)setHorizontalPadding:(CGFloat)hPadding vertical:(CGFloat)vPadding;
- (void)setMinimumColumns:(NSInteger)min maximum:(NSInteger)max;


@end

@protocol IconGridDelegate <NSObject>

- (void)iconGridFrameDidChange:(IconGrid *)iconGrid;

@end

