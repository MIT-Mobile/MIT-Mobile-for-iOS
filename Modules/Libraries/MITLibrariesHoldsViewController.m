#import "MITLibrariesHoldsViewController.h"
#import "MITLibrariesItemHoldCell.h"

static NSString *const kMITLibrariesItemHoldCell = @"MITLibrariesItemHoldCell";

@interface MITLibrariesHoldsViewController ()

@property (nonatomic, strong) UILabel *tableHeaderLabel;

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
    
    UIView *tableHeaderContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 34)];
    self.tableHeaderLabel = [[UILabel alloc] initWithFrame:CGRectInset(tableHeaderContainer.frame, 8, 5)];
    [tableHeaderContainer addSubview:self.tableHeaderLabel];
    
    self.tableView.tableHeaderView = tableHeaderContainer;
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITLibrariesItemHoldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITLibrariesItemHoldCell];
    
    [cell setContent:self.items[indexPath.row]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [MITLibrariesItemHoldCell heightForContent:self.items[indexPath.row] tableViewWidth:self.tableView.frame.size.width];
}

- (void)setItems:(NSArray *)items
{
    [super setItems:items];
    [self updateHeaderLabel];
}

- (void)updateHeaderLabel
{
    // TODO: Pending confirmation on holds webservice
}

@end
