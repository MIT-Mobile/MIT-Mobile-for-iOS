#import "MITLibrariesHoldsViewController.h"

@interface MITLibrariesHoldsViewController ()

@end

@implementation MITLibrariesHoldsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupTableView];
    
    self.view.backgroundColor = [UIColor blueColor];
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
