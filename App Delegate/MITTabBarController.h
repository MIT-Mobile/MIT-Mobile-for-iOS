#import <UIKit/UIKit.h>

@protocol MITTabBarControllerDelegate;

@class MITMoreListController;

@interface MITTabBarController : UIViewController <UITabBarDelegate, UINavigationControllerDelegate, UINavigationBarDelegate> {
    id<MITTabBarControllerDelegate> delegate;
    UITabBar *theTabBar;
    UIView *containingView;
    UIView *limboView;
    UINavigationController *moreNavigationController;
    MITMoreListController *moreListController;
    
    NSArray *allItems; // all UITabBarItems managed by this controller, not just the visible ones and not including More tab itself
    NSArray *viewControllers; // view controllers for allItems, aligned by index
    NSArray *customizableViewControllers; // only the view controllers of viewControllers which should appear when customizing the tab bar
    
    UIViewController *selectedViewController; // the selected tab's view controller. could be the More tab but never one of the tabs under it.
    UITabBarItem *activeItem; // the currently visible tabBarItem among tabBarItems (includes items visited under the More tab)
    
    NSArray *activeTabNavStack;
    NSArray *pendingNavigationStack; // implementation detail for delayed setting of More tab's navstack
}

- (NSArray *)viewControllers;
- (void)setViewControllers:(NSArray *)newViewControllers;
- (NSArray *)customizableViewControllers;
- (void)setCustomizableViewControllers:(NSArray *)newCustomizableViewControllers;
- (void)updateTabBarItems;
- (void)showViewController:(UIViewController *)viewController;
- (void)showItem:(UITabBarItem *)item;
- (void)displayItem:(UITabBarItem *)item immediate:(BOOL)immediate;
- (void)showItemOnMoreList:(UITabBarItem *)item;
- (void)showItemOnMoreList:(UITabBarItem *)item animated:(BOOL)animated;

@property (nonatomic, retain) id<MITTabBarControllerDelegate> delegate;
@property (nonatomic, retain) UITabBar *tabBar;
@property (nonatomic, copy) NSArray *viewControllers;
@property (nonatomic, copy) NSArray *customizableViewControllers;
@property (nonatomic, readonly) UINavigationController *moreNavigationController;
@property (nonatomic, retain) UIViewController *selectedViewController;
@property (nonatomic, retain) UITabBarItem *activeItem;
@property (nonatomic, retain) NSArray *activeTabNavStack;
@property (nonatomic, readonly) NSArray *allItems;

@end

@protocol MITTabBarControllerDelegate <NSObject>

@optional

- (void)tabBarController:(MITTabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController;
- (void)tabBarController:(MITTabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed;
- (void)tabBarController:(MITTabBarController *)tabBarController didShowItem:(UITabBarItem *)item;

@end
