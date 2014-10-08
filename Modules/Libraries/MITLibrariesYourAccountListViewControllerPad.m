#import "MITLibrariesYourAccountListViewControllerPad.h"
#import "MITLibrariesItemLoanFineCell.h"
#import "MITLibrariesItemHoldCell.h"

static NSString *const kMITLibrariesItemLoanFineCell = @"MITLibrariesItemLoanFineCell";
static NSString *const kMITLibrariesItemHoldCell = @"MITLibrariesItemHoldCell";

@interface MITLibrariesYourAccountListViewControllerPad ()

@end

@implementation MITLibrariesYourAccountListViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupTableView];
}

- (void)setupTableView
{
    UINib *cellNib = [UINib nibWithNibName:kMITLibrariesItemLoanFineCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITLibrariesItemLoanFineCell];
    
    cellNib = [UINib nibWithNibName:kMITLibrariesItemHoldCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITLibrariesItemHoldCell];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[UITableViewCell alloc] init];
}

@end
