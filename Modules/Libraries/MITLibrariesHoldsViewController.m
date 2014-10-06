#import "MITLibrariesHoldsViewController.h"
#import "MITLibrariesItemHoldCell.h"

static NSString *const kMITLibrariesItemHoldCell = @"MITLibrariesItemHoldCell";

@interface MITLibrariesHoldsViewController ()

@end

@implementation MITLibrariesHoldsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Holds";
    
    [self setupTableView];
}

- (void)setupTableView
{
    UINib *cellNib = [UINib nibWithNibName:kMITLibrariesItemHoldCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITLibrariesItemHoldCell];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITLibrariesItemHoldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITLibrariesItemHoldCell];
    
    [cell setContent:self.items[indexPath.row]];
    
    return cell;
}

@end
