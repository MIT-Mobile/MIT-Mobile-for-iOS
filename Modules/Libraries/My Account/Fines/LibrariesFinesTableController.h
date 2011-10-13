#import <Foundation/Foundation.h>

@interface LibrariesFinesTableController : NSObject <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic,retain) UIViewController *parentController;
@property (nonatomic,retain) UITableView *tableView;

- (id)initWithTableView:(UITableView*)tableView;

- (void)tabWillBecomeActive;
- (void)tabDidBecomeActive;
- (void)tabWillBecomeInactive;
- (void)tabDidBecomeInactive;

@end
