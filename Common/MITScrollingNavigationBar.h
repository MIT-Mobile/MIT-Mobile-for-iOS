#import <UIKit/UIKit.h>

@protocol MITScrollingNavigationBarDataSource;
@protocol MITScrollingNavigationBarDelegate;

@interface MITScrollingNavigationBar : UIView
@property (nonatomic,weak) id<MITScrollingNavigationBarDataSource> dataSource;
@property (nonatomic,weak) id<MITScrollingNavigationBarDelegate> delegate;

@end

@protocol MITScrollingNavigationBarDataSource <NSObject>
- (NSUInteger)numberOfItemsInNavigationBar:(MITScrollingNavigationBar*)navigationBar;
- (NSAttributedString*)navigationBar:(MITScrollingNavigationBar*)navigationBar
             titleForItemAtIndexPath:(NSIndexPath*)indexPath;
- (NSAttributedString*)navigationBar:(MITScrollingNavigationBar *)navigationBar
  highlightedTitleForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSAttributedString*)navigationBar:(MITScrollingNavigationBar *)navigationBar
     selectedTitleForItemAtIndexPath:(NSIndexPath *)indexPath;
@end

@protocol MITScrollingNavigationBarDelegate <NSObject>
@optional
- (BOOL)shouldShowSearchItemInNavigationBar:(MITScrollingNavigationBar*)navigationBar;
- (void)didSelectSearchItemInNavigationBar:(MITScrollingNavigationBar*)navigationBar;
- (void)didSelectItemAtIndexPath:(NSIndexPath*)indexPath;
@end