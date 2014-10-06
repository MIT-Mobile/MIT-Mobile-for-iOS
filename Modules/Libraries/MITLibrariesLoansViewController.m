#import "MITLibrariesLoansViewController.h"

@interface MITLibrariesLoansViewController ()

@end

@implementation MITLibrariesLoansViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupTableView];
    
    self.view.backgroundColor = [UIColor redColor];
}

- (void)setupTableView
{
    [super setupTableView];
    
}

#pragma mark - Table view data source


/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/


@end
