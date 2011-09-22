#import <Foundation/Foundation.h>

@interface LibrariesLoanTableController : NSObject <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic,retain) UIViewController *parentController;
@property (nonatomic,retain) UITableView *tableView;

- (id)initWithTableView:(UITableView*)tableView;

@end
