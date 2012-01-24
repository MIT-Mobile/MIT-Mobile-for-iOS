#import <Foundation/Foundation.h>
#import "LibrariesHoldsSummaryView.h"

@class LibrariesAccountViewController;

@interface LibrariesHoldsTabController : NSObject <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic,retain) LibrariesAccountViewController *parentController;
@property (nonatomic,retain) UITableView *tableView;
@property (nonatomic,retain) LibrariesHoldsSummaryView* headerView;

- (id)initWithTableView:(UITableView*)tableView;

- (void)tabWillBecomeActive;
- (void)tabDidBecomeActive;
- (void)tabWillBecomeInactive;
- (void)tabDidBecomeInactive;
@end
