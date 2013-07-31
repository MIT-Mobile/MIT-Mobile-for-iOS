#import <Foundation/Foundation.h>
#import "LibrariesHoldsSummaryView.h"

@class LibrariesAccountViewController;

@interface LibrariesHoldsTabController : NSObject <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic,weak) LibrariesAccountViewController *parentController;
@property (nonatomic,weak) UITableView *tableView;
@property (nonatomic,strong) LibrariesHoldsSummaryView* headerView;

- (id)initWithTableView:(UITableView*)tableView;

- (void)tabWillBecomeActive;
@end
