#import <Foundation/Foundation.h>
#import "LibrariesLoanSummaryView.h"

@class LibrariesAccountViewController;

@protocol MITTabViewHidingDelegate <NSObject>
@optional
- (void)setTabBarHidden:(BOOL)tabBarHidden animated:(BOOL)animated;
- (void)setTabBarHidden:(BOOL)tabBarHidden animated:(BOOL)animated finished:(void (^)())finished;
@end

@interface LibrariesLoanTabController : NSObject <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic,strong) LibrariesLoanSummaryView *headerView;
@property (nonatomic,weak) LibrariesAccountViewController *parentController;
@property (nonatomic,weak) UITableView *tableView;
@property (nonatomic,weak) id<MITTabViewHidingDelegate> tabViewHidingDelegate;

- (id)initWithTableView:(UITableView*)tableView;

- (void)tabWillBecomeActive;
- (void)tabDidBecomeActive;
- (void)tabWillBecomeInactive;

@end
