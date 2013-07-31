#import <Foundation/Foundation.h>
#import "LibrariesFinesSummaryView.h"

@class LibrariesAccountViewController;

@interface LibrariesFinesTabController : NSObject <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic,weak) LibrariesAccountViewController *parentController;
@property (nonatomic,weak) UITableView *tableView;
@property (nonatomic,strong) LibrariesFinesSummaryView* headerView;

- (id)initWithTableView:(UITableView*)tableView;

- (void)tabWillBecomeActive;
@end
