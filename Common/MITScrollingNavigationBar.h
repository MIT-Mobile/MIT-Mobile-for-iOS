#import <UIKit/UIKit.h>

@protocol MITScrollingNavigationBarDataSource;
@protocol MITScrollingNavigationBarDelegate;

@interface MITScrollingNavigationBar : UIView
@property (nonatomic) NSInteger selectedIndex;
@property (nonatomic,weak) id<MITScrollingNavigationBarDataSource> dataSource;
@property (nonatomic,weak) id<MITScrollingNavigationBarDelegate> delegate;

- (void)reloadData;
@end

@protocol MITScrollingNavigationBarDataSource <NSObject>
- (NSUInteger)numberOfItemsInNavigationBar:(MITScrollingNavigationBar*)navigationBar;
- (NSString*)navigationBar:(MITScrollingNavigationBar*)navigationBar titleForItemAtIndex:(NSInteger)index;
@end

@protocol MITScrollingNavigationBarDelegate <NSObject>
@optional
- (CGFloat)widthForAccessoryViewInNavigationBar:(MITScrollingNavigationBar*)navigationBar;
- (UIView*)accessoryViewForNavigationBar:(MITScrollingNavigationBar*)navigationBar;
- (void)navigationBar:(MITScrollingNavigationBar*)navigationBar didSelectItemAtIndex:(NSInteger)index;
@end