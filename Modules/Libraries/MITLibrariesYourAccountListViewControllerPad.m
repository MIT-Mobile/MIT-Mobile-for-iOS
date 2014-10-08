#import "MITLibrariesYourAccountListViewControllerPad.h"
#import "MITLibrariesItemLoanFineCell.h"
#import "MITLibrariesItemHoldCell.h"
#import "MITLibrariesUser.h"

static NSString *const kMITLibrariesItemLoanFineCell = @"MITLibrariesItemLoanFineCell";
static NSString *const kMITLibrariesItemHoldCell = @"MITLibrariesItemHoldCell";

typedef NS_ENUM(NSInteger, kMITAccountListSection) {
    kMITAccountListSectionLoans,
    kMITAccountListSectionFines,
    kMITAccountListSectionHolds
};

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
        case kMITAccountListSectionLoans:
            return self.user.loans.count;
            break;
        case kMITAccountListSectionFines:
            return self.user.fines.count;
            break;
        case kMITAccountListSectionHolds:
            return self.user.holds.count;
            break;
        default:
            return 0;
            break;
    }
}

// TODO: Real headers
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case kMITAccountListSectionLoans:
            return @"Loans";
            break;
        case kMITAccountListSectionFines:
            return @"Fines";
            break;
        case kMITAccountListSectionHolds:
            return @"Holds";
            break;
        default:
            return @"";
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    CGFloat width = self.tableView.frame.size.width;
    
    switch (indexPath.section) {
        case kMITAccountListSectionLoans:
            return [MITLibrariesItemLoanFineCell heightForContent:self.user.loans[row]
                                                   tableViewWidth:width];
            break;
        case kMITAccountListSectionFines:
            return [MITLibrariesItemLoanFineCell heightForContent:self.user.fines[row]
                                                   tableViewWidth:width];
            break;
        case kMITAccountListSectionHolds:
            return [MITLibrariesItemHoldCell heightForContent:self.user.holds[row]
                                                   tableViewWidth:width];
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kMITAccountListSectionLoans: {
            MITLibrariesItemLoanFineCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITLibrariesItemLoanFineCell forIndexPath:indexPath];
            [cell setContent:self.user.loans[indexPath.row]];
            return cell;
            break;
        }
        case kMITAccountListSectionFines: {
            MITLibrariesItemLoanFineCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITLibrariesItemLoanFineCell forIndexPath:indexPath];
            [cell setContent:self.user.fines[indexPath.row]];
            return cell;
            break;
        }
        case kMITAccountListSectionHolds: {
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

- (void)setUser:(MITLibrariesUser *)user
{
    _user = user;
    [self.tableView reloadData];
}

@end
