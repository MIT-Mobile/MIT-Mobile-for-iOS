#import <Foundation/Foundation.h>
#import "LibrariesLoanSummaryView.h"

@interface LibrariesLoanTabController : NSObject <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic,retain) LibrariesLoanSummaryView *headerView;
@property (nonatomic,retain) UIViewController *parentController;
@property (nonatomic,retain) UITableView *tableView;

- (id)initWithTableView:(UITableView*)tableView;

- (void)tabWillBecomeActive;
- (void)tabDidBecomeActive;
- (void)tabWillBecomeInactive;
- (void)tabDidBecomeInactive;

@end
