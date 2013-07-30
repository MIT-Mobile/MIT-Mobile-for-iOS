#import <Foundation/Foundation.h>
#import "LibrariesFinesSummaryView.h"

@class LibrariesAccountViewController;

@interface LibrariesFinesTabController : NSObject <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic,weak) LibrariesAccountViewController *parentController;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,weak) LibrariesFinesSummaryView* headerView;

- (id)initWithTableView:(UITableView*)tableView;

- (void)tabWillBecomeActive;
@end
