#import <Foundation/Foundation.h>
#import "LibrariesLoanSummaryView.h"

@class LibrariesAccountViewController;

@protocol MITTabViewHidingDelegate <NSObject>
@optional
- (void)setTabBarHidden:(BOOL)tabBarHidden animated:(BOOL)animated;
- (void)setTabBarHidden:(BOOL)tabBarHidden animated:(BOOL)animated finished:(void (^)())finished;
@end

@interface LibrariesLoanTabController : NSObject <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic,retain) LibrariesLoanSummaryView *headerView;
@property (nonatomic,retain) LibrariesAccountViewController *parentController;
@property (nonatomic,retain) UITableView *tableView;
@property (nonatomic,assign) id<MITTabViewHidingDelegate> tabViewHidingDelegate;

- (id)initWithTableView:(UITableView*)tableView;

- (void)tabWillBecomeActive;
- (void)tabDidBecomeActive;
- (void)tabWillBecomeInactive;
- (void)tabDidBecomeInactive;

@end
