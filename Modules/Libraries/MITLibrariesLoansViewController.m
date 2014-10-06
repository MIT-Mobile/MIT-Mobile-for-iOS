#import "MITLibrariesLoansViewController.h"
#import "MITLibrariesItemLoanFineCell.h"

static NSString *const kMITLibrariesItemLoanFineCell = @"MITLibrariesItemLoanFineCell";

@interface MITLibrariesLoansViewController ()

@end

@implementation MITLibrariesLoansViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Loans";
    
    [self setupTableView];
}

- (void)setupTableView
{   
    UINib *cellNib = [UINib nibWithNibName:kMITLibrariesItemLoanFineCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITLibrariesItemLoanFineCell];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITLibrariesItemLoanFineCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITLibrariesItemLoanFineCell];
    
    [cell setContent:self.items[indexPath.row]];
    
    return cell;
}

@end
