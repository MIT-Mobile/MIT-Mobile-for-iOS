#import <UIKit/UIKit.h>

@protocol MITScrollingNavigationBarDataSource;
@protocol MITScrollingNavigationBarDelegate;

@interface MITScrollingNavigationBar : UIView
@property (nonatomic,weak) id<MITScrollingNavigationBarDataSource> dataSource;
@property (nonatomic,weak) id<MITScrollingNavigationBarDelegate> delegate;

@end

@protocol MITScrollingNavigationBarDataSource <NSObject>
- (NSUInteger)numberOfItemsInNavigationBar:(MITScrollingNavigationBar*)navigationBar;
- (NSString*)navigationBar:(MITScrollingNavigationBar*)navigationBar titleForItemAtIndexPath:(NSIndexPath*)indexPath;
@end

@protocol MITScrollingNavigationBarDelegate <NSObject>
@optional
- (BOOL)shouldShowSearchItemInNavigationBar:(MITScrollingNavigationBar*)navigationBar;
- (void)didSelectSearchItemInNavigationBar:(MITScrollingNavigationBar*)navigationBar;
- (void)navigationBar:(MITScrollingNavigationBar*)navigationBar didSelectItemAtIndexPath:(NSIndexPath*)indexPath;
@end