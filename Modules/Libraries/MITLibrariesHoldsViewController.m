#import "MITLibrariesHoldsViewController.h"
#import "MITLibrariesItemHoldCell.h"
#import "MITLibrariesYourAccountItemDetailViewController.h"
#import "UIKit+MITAdditions.h"

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MITLibrariesYourAccountItemDetailViewController *detailVC = [[MITLibrariesYourAccountItemDetailViewController alloc] initWithNibName:nil bundle:nil];
    detailVC.item = self.items[indexPath.row];
    [self.navigationController pushViewController:detailVC animated:YES];
}

- (void)setItems:(NSArray *)items
{
    [super setItems:items];
    [self updateHeaderLabel];
}

- (void)updateHeaderLabel
{
    NSMutableAttributedString *baseString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d holds, ", self.items.count]
                                                                                   attributes:@{NSForegroundColorAttributeName : [UIColor mit_greyTextColor],
                                                                                                NSFontAttributeName : [UIFont systemFontOfSize:14.0]}];
    NSAttributedString *readyForPickupString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d ready for pickup", self.readyForPickupCount]
                                                                        attributes:@{NSForegroundColorAttributeName : [UIColor mit_openGreenColor],
                                                                                     NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}];
    
    [baseString appendAttributedString:readyForPickupString];
    
    self.tableHeaderLabel.attributedText = baseString;
}

@end
