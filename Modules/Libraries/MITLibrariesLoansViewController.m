#import "MITLibrariesLoansViewController.h"
#import "MITLibrariesItemLoanFineCell.h"
#import "MITLibrariesMITLoanItem.h"
#import "UIKit+MITAdditions.h"

static NSString *const kMITLibrariesItemLoanFineCell = @"MITLibrariesItemLoanFineCell";

@interface MITLibrariesLoansViewController ()

@property (nonatomic, strong) UILabel *tableHeaderLabel;

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
    
    UIView *tableHeaderContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 34)];
    self.tableHeaderLabel = [[UILabel alloc] initWithFrame:CGRectInset(tableHeaderContainer.frame, 8, 5)];
    [tableHeaderContainer addSubview:self.tableHeaderLabel];
    
    self.tableView.tableHeaderView = tableHeaderContainer;
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITLibrariesItemLoanFineCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITLibrariesItemLoanFineCell];
    
    [cell setContent:self.items[indexPath.row]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [MITLibrariesItemLoanFineCell heightForContent:self.items[indexPath.row] tableViewWidth:self.tableView.frame.size.width];
}

- (void)setItems:(NSArray *)items
{
    [super setItems:items];
    [self updateHeaderLabel];
}

- (void)updateHeaderLabel
{
    NSInteger overdueItems = 0;
    for (MITLibrariesMITLoanItem *item in self.items) {
        if (item.overdue) {
            overdueItems++;
        }
    }
    
    NSMutableAttributedString *baseString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d items, ", self.items.count]
                                                                                      attributes:@{NSForegroundColorAttributeName : [UIColor mit_greyTextColor],
                                                                                                              NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}];
    NSAttributedString *overdueString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d overdue", overdueItems]
                                                                        attributes:@{NSForegroundColorAttributeName : [UIColor mit_closedRedColor],
                                                                                                NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}];
    
    [baseString appendAttributedString:overdueString];
    
    self.tableHeaderLabel.attributedText = baseString;
}

@end
