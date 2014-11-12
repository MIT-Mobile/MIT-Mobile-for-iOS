#import "MITLibrariesYourAccountListViewControllerPad.h"
#import "MITLibrariesItemLoanFineCell.h"
#import "MITLibrariesItemHoldCell.h"
#import "MITLibrariesUser.h"
#import "UIKit+MITAdditions.h"
#import "UIKit+MITLibraries.h"
#import "MITLibrariesYourAccountItemDetailViewController.h"
#import "MITLibrariesYourAccountCollectionViewHeader.h"

static NSString *const kMITLibrariesItemLoanFineCell = @"MITLibrariesItemLoanFineCell";
static NSString *const kMITLibrariesItemHoldCell = @"MITLibrariesItemHoldCell";

typedef NS_ENUM(NSInteger, MITAccountListSection) {
    MITAccountListSectionLoans,
    MITAccountListSectionFines,
    MITAccountListSectionHolds
};

@interface MITLibrariesYourAccountListViewControllerPad ()

@property (nonatomic, strong) UIView *loansHeaderView;
@property (nonatomic, strong) UIView *finesHeaderView;
@property (nonatomic, strong) UIView *holdsHeaderView;
@property (nonatomic, assign) CGFloat previousYOffset;

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
    
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 20)];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)setUser:(MITLibrariesUser *)user
{
    _user = user;
    [self resetTableHeaders];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.user) {
        return 3;
    }
    else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.user) {
        return 0;
    }
    
    switch (section) {
        case MITAccountListSectionLoans:
            return self.user.loans.count;
            break;
        case MITAccountListSectionFines:
            return self.user.fines.count;
            break;
        case MITAccountListSectionHolds:
            return self.user.holds.count;
            break;
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    CGFloat width = self.tableView.frame.size.width;
    
    switch (indexPath.section) {
        case MITAccountListSectionLoans:
            return [MITLibrariesItemLoanFineCell heightForContent:self.user.loans[row]
                                                   tableViewWidth:width];
            break;
        case MITAccountListSectionFines:
            return [MITLibrariesItemLoanFineCell heightForContent:self.user.fines[row]
                                                   tableViewWidth:width];
            break;
        case MITAccountListSectionHolds:
            return [MITLibrariesItemHoldCell heightForContent:self.user.holds[row]
                                                   tableViewWidth:width];
            break;
        default:
            return 0;
            break;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case MITAccountListSectionLoans:
            return self.loansHeaderView;
            break;
        case MITAccountListSectionHolds:
            return self.holdsHeaderView;
            break;
        case MITAccountListSectionFines:
            return self.finesHeaderView;
            break;
        default:
            return [UIView new];
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case MITAccountListSectionLoans: {
            return [MITLibrariesYourAccountCollectionViewHeader heightForAttributedString:[self loansHeaderString] width:self.tableView.bounds.size.width];
        }
        case MITAccountListSectionHolds: {
            return [MITLibrariesYourAccountCollectionViewHeader heightForAttributedString:[self holdsHeaderString] width:self.tableView.bounds.size.width];
        }
        case MITAccountListSectionFines: {
            return [MITLibrariesYourAccountCollectionViewHeader heightForAttributedString:[self finesHeaderString] width:self.tableView.bounds.size.width];
        }
        default: {
            return 0;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case MITAccountListSectionLoans: {
            MITLibrariesItemLoanFineCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITLibrariesItemLoanFineCell forIndexPath:indexPath];
            [cell setContent:self.user.loans[indexPath.row]];
            cell.ipadSeparator.hidden = NO;
            return cell;
            break;
        }
        case MITAccountListSectionFines: {
            MITLibrariesItemLoanFineCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITLibrariesItemLoanFineCell forIndexPath:indexPath];
            [cell setContent:self.user.fines[indexPath.row]];
            cell.ipadSeparator.hidden = NO;
            return cell;
            break;
        }
        case MITAccountListSectionHolds: {
            MITLibrariesItemHoldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITLibrariesItemHoldCell forIndexPath:indexPath];
            [cell setContent:self.user.holds[indexPath.row]];
            cell.ipadSeparator.hidden = NO;
            return cell;
            break;
        }
        default:
            return 0;
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"loans header: %f", self.loansHeaderView.frame.origin.y - self.tableView.contentOffset.y);
    return;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MITLibrariesMITItem *selectedItem = nil;
    switch (indexPath.section) {
        case MITAccountListSectionLoans: {
            selectedItem = self.user.loans[indexPath.row];
            break;
        }
        case MITAccountListSectionFines: {
            selectedItem = self.user.fines[indexPath.row];
            break;
        }
        case MITAccountListSectionHolds: {
            selectedItem = self.user.holds[indexPath.row];
            break;
        }
        default:
            return;
            break;
    }
    
    MITLibrariesYourAccountItemDetailViewController *detailVC = [[MITLibrariesYourAccountItemDetailViewController alloc] initWithNibName:nil bundle:nil];
    detailVC.item = selectedItem;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:detailVC];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:^{}];
}

#pragma mark - Account Headers

- (UIView *)loansHeaderView
{
    if (!_loansHeaderView) {
        _loansHeaderView = [self headerWithAttributedText:[self loansHeaderString]];
    }
    return _loansHeaderView;
}

- (UIView *)finesHeaderView
{
    if (!_finesHeaderView) {
        _finesHeaderView = [self headerWithAttributedText:[self finesHeaderString]];
    }
    return _finesHeaderView;
}

- (UIView *)holdsHeaderView
{
    if (!_holdsHeaderView) {
        _holdsHeaderView = [self headerWithAttributedText:[self holdsHeaderString]];
    }
    return _holdsHeaderView;
}

- (void)resetTableHeaders
{
    self.finesHeaderView = nil;
    self.loansHeaderView = nil;
    self.holdsHeaderView = nil;
}

- (MITLibrariesYourAccountCollectionViewHeader *)headerWithAttributedText:(NSAttributedString *)attributedText
{
    MITLibrariesYourAccountCollectionViewHeader *header = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MITLibrariesYourAccountCollectionViewHeader class]) owner:self options:nil] firstObject];
    [header setAttributedString:attributedText];
    return header;
}

- (NSAttributedString *)loansHeaderString
{
    NSMutableAttributedString *baseString = [[NSMutableAttributedString alloc] initWithString:@"Loans " attributes:@{NSFontAttributeName : [UIFont librariesTitleStyleFont]}];
    
    [baseString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d items, ", self.user.loans.count]
                                                                              attributes:@{NSForegroundColorAttributeName : [UIColor mit_greyTextColor],
                                                                                           NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}]];
    
    NSAttributedString *overdueString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d overdue", self.user.overdueItemsCount]
                                                                        attributes:@{NSForegroundColorAttributeName : [UIColor mit_closedRedColor],
                                                                                     NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}];
    
    [baseString appendAttributedString:overdueString];
    
    return [[NSAttributedString alloc] initWithAttributedString:baseString];
}

- (NSAttributedString *)finesHeaderString
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"M/d/yyyy"];
    }
    
    NSMutableAttributedString *baseString = [[NSMutableAttributedString alloc] initWithString:@"Fines " attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17.0]}];
    
    [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:self.user.formattedBalance
                                                                       attributes:@{NSForegroundColorAttributeName : [UIColor mit_closedRedColor],
                                                                                    NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}]];
    
    NSAttributedString *detailsString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" as of %@.\nPayable at any MIT library service desk. TechCASH accepted only at Hayden Library.", [dateFormatter stringFromDate:[NSDate date]]]
                                                                        attributes:@{NSForegroundColorAttributeName : [UIColor mit_greyTextColor],
                                                                                     NSFontAttributeName : [UIFont systemFontOfSize:14.0]}];
    
    [baseString appendAttributedString:detailsString];
    
    return [[NSAttributedString alloc] initWithAttributedString:baseString];
}

- (NSAttributedString *)holdsHeaderString
{
    NSMutableAttributedString *baseString = [[NSMutableAttributedString alloc] initWithString:@"Holds " attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17.0]}];
    
    [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d holds, ", self.user.holds.count]
                                                                       attributes:@{NSForegroundColorAttributeName : [UIColor mit_greyTextColor],
                                                                                    NSFontAttributeName : [UIFont systemFontOfSize:14.0]}]];
    
    NSAttributedString *readyForPickupString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d ready for pickup", self.user.readyForPickupCount]
                                                                               attributes:@{NSForegroundColorAttributeName : [UIColor mit_openGreenColor],
                                                                                            NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}];
    
    [baseString appendAttributedString:readyForPickupString];
    
    return [[NSAttributedString alloc] initWithAttributedString:baseString];
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.tableView.numberOfSections < 3) {
        return;
    }
    
    CGFloat yOffset = self.tableView.contentOffset.y;
    
    CGFloat loansSectionTop = [self.tableView rectForSection:0].origin.y;
    CGFloat finesSectionTop = [self.tableView rectForSection:1].origin.y;
    CGFloat holdsSectionTop = [self.tableView rectForSection:2].origin.y;
    
    if (yOffset >= loansSectionTop && self.previousYOffset < loansSectionTop) {
        self.loansHeaderView.backgroundColor = [UIColor mit_cellSeparatorColor];
    } else if (yOffset < loansSectionTop && self.previousYOffset >= loansSectionTop) {
        self.loansHeaderView.backgroundColor = [UIColor whiteColor];
    }
    
    if (yOffset >= finesSectionTop && self.previousYOffset < finesSectionTop) {
        self.finesHeaderView.backgroundColor = [UIColor mit_cellSeparatorColor];
    } else if (yOffset < finesSectionTop && self.previousYOffset >= finesSectionTop) {
        self.finesHeaderView.backgroundColor = [UIColor whiteColor];
    }
    
    if (yOffset >= holdsSectionTop && self.previousYOffset < holdsSectionTop) {
        self.holdsHeaderView.backgroundColor = [UIColor mit_cellSeparatorColor];
    } else if (yOffset < holdsSectionTop && self.previousYOffset >= holdsSectionTop) {
        self.holdsHeaderView.backgroundColor = [UIColor whiteColor];
    }
    
    self.previousYOffset = yOffset;
}

@end
