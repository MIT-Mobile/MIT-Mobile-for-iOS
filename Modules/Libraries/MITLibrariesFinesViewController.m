#import "MITLibrariesFinesViewController.h"
#import "MITLibrariesItemLoanFineCell.h"
#import "UIKit+MITAdditions.h"

static NSString *const kMITLibrariesItemLoanFineCell = @"MITLibrariesItemLoanFineCell";

@interface MITLibrariesFinesViewController ()

@property (nonatomic, strong) UILabel *tableHeaderLabel;

@end

@implementation MITLibrariesFinesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Fines";
    
    [self setupTableView];
}

- (void)setupTableView
{
    UINib *cellNib = [UINib nibWithNibName:kMITLibrariesItemLoanFineCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITLibrariesItemLoanFineCell];
    
    UIView *tableHeaderContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 67)];
    self.tableHeaderLabel = [[UILabel alloc] initWithFrame:CGRectInset(tableHeaderContainer.frame, 8, 5)];
    self.tableHeaderLabel.numberOfLines = 3;
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

- (void)setFinesBalance:(NSString *)finesBalance
{
    _finesBalance = finesBalance;
    [self updateHeaderLabel];
}

- (void)updateHeaderLabel
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"M/d/yyyy"];
    }
    
    NSMutableAttributedString *fineAmountString = [[NSMutableAttributedString alloc] initWithString:self.finesBalance
                                                                     attributes:@{NSForegroundColorAttributeName : [UIColor mit_closedRedColor],
                                                                                  NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}];
    
    NSAttributedString *detailsString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" as of %@.\nPayable at any MIT library service desk.\nTechCASH accepted only at Hayden Library.", [dateFormatter stringFromDate:[NSDate date]]]
                                                                        attributes:@{NSForegroundColorAttributeName : [UIColor mit_greyTextColor],
                                                                                     NSFontAttributeName : [UIFont systemFontOfSize:14.0]}];
    
    [fineAmountString appendAttributedString:detailsString];
    
    self.tableHeaderLabel.attributedText = fineAmountString;
}

@end
