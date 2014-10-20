#import "MITLibrariesYourAccountListViewControllerPad.h"
#import "MITLibrariesItemLoanFineCell.h"
#import "MITLibrariesItemHoldCell.h"
#import "MITLibrariesUser.h"
#import "UIKit+MITAdditions.h"
#import "UIKit+MITLibraries.h"

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
        case MITAccountListSectionLoans:
        case MITAccountListSectionHolds:
            return 34.0;
            break;
        case MITAccountListSectionFines:
            return 67.0;
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case MITAccountListSectionLoans: {
            MITLibrariesItemLoanFineCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITLibrariesItemLoanFineCell forIndexPath:indexPath];
            [cell setContent:self.user.loans[indexPath.row]];
            return cell;
            break;
        }
        case MITAccountListSectionFines: {
            MITLibrariesItemLoanFineCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITLibrariesItemLoanFineCell forIndexPath:indexPath];
            [cell setContent:self.user.fines[indexPath.row]];
            return cell;
            break;
        }
        case MITAccountListSectionHolds: {
            MITLibrariesItemHoldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITLibrariesItemHoldCell forIndexPath:indexPath];
            [cell setContent:self.user.holds[indexPath.row]];
            return cell;
            break;
        }
        default:
            return 0;
            break;
    }
}

- (UIView *)loansHeaderView
{
    if (!_loansHeaderView) {
        NSMutableAttributedString *baseString = [[NSMutableAttributedString alloc] initWithString:@"Loans " attributes:@{NSFontAttributeName : [UIFont librariesTitleStyleFont]}];
        
        [baseString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d items, ", self.user.loans.count]
                                                                                  attributes:@{NSForegroundColorAttributeName : [UIColor mit_greyTextColor],
                                                                                               NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}]];
        
        NSAttributedString *overdueString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d overdue", self.user.overdueItemsCount]
                                                                            attributes:@{NSForegroundColorAttributeName : [UIColor mit_closedRedColor],
                                                                                         NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}];
        
        [baseString appendAttributedString:overdueString];
        
        _loansHeaderView = [self embeddedLabelWithAttributedText:baseString height:34.0];
    }
    return _loansHeaderView;
}

- (UIView *)finesHeaderView
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"M/d/yyyy"];
    }
    
    if (!_finesHeaderView) {
        NSMutableAttributedString *baseString = [[NSMutableAttributedString alloc] initWithString:@"Fines " attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17.0]}];
        
        [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:self.user.formattedBalance
                                                                           attributes:@{NSForegroundColorAttributeName : [UIColor mit_closedRedColor],
                                                                                        NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}]];
        
        NSAttributedString *detailsString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" as of %@.\nPayable at any MIT library service desk.\nTechCASH accepted only at Hayden Library.", [dateFormatter stringFromDate:[NSDate date]]]
                                                                            attributes:@{NSForegroundColorAttributeName : [UIColor mit_greyTextColor],
                                                                                         NSFontAttributeName : [UIFont systemFontOfSize:14.0]}];
        
        [baseString appendAttributedString:detailsString];
        
        _finesHeaderView = [self embeddedLabelWithAttributedText:baseString height:67.0];
    }
    return _finesHeaderView;
}

- (UIView *)holdsHeaderView
{
    if (!_holdsHeaderView) {
        NSMutableAttributedString *baseString = [[NSMutableAttributedString alloc] initWithString:@"Holds " attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17.0]}];
        
        [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d holds, ", self.user.holds.count]
                                                                           attributes:@{NSForegroundColorAttributeName : [UIColor mit_greyTextColor],
                                                                                        NSFontAttributeName : [UIFont systemFontOfSize:14.0]}]];
        
        NSAttributedString *readyForPickupString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d ready for pickup", self.user.readyForPickupCount]
                                                                                   attributes:@{NSForegroundColorAttributeName : [UIColor mit_openGreenColor],
                                                                                                NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}];
        
        [baseString appendAttributedString:readyForPickupString];
        
        _holdsHeaderView = [self embeddedLabelWithAttributedText:baseString height:34.0];
    }
    return _holdsHeaderView;
}

- (void)resetTableHeaders
{
    self.finesHeaderView = nil;
    self.loansHeaderView = nil;
    self.holdsHeaderView = nil;
}

- (UIView *)embeddedLabelWithAttributedText:(NSAttributedString *)attributedText height:(CGFloat)height
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, height)];
    view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(view.frame, 8, 5)];
    label.numberOfLines = 0;
    
    label.attributedText = attributedText;
    
    [view addSubview:label];
    
    return view;
}

- (void)setUser:(MITLibrariesUser *)user
{
    _user = user;
    [self resetTableHeaders];
    [self.tableView reloadData];
}

@end
