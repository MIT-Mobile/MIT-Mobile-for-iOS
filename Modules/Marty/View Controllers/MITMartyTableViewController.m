#import "MITMartyTableViewController.h"
#import "MITActionCell.h"
#import "MITMartyDetailHeaderView.h"
#import "UITableView+DynamicSizing.h"
#import "MITTitleDescriptionCell.h"

static NSString * const MITActionCellIdentifier = @"MITActionCellIdentifier";
static NSString * const MITTitleDescriptionCellIdentifier = @"MITTitleDescriptionCellIdentifier";
static NSString * const MITMartyDetailHeaderViewIdentifier = @"MITMartyDetailHeaderViewIdentifier";
static NSString * const MITMartyDetailHeaderViewNIB = @"MITMartyDetailHeaderView";

@interface MITMartyTableViewController () <UITableViewDataSource, UITableViewDelegate, UITableViewDataSourceDynamicSizing>

@end

@implementation MITMartyTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[MITActionCell actionCellNib] forDynamicCellReuseIdentifier:MITActionCellIdentifier];

    [self.tableView registerNib:[MITTitleDescriptionCell titleDescriptionCellNib] forDynamicCellReuseIdentifier:MITTitleDescriptionCellIdentifier];

    [self.tableView registerNib:[UINib nibWithNibName:MITMartyDetailHeaderViewNIB bundle:nil] forHeaderFooterViewReuseIdentifier:MITMartyDetailHeaderViewIdentifier];
    
}

- (void)tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0 ) {
        MITActionCell *cell = [tableView dequeueReusableCellWithIdentifier:MITActionCellIdentifier];
        [cell setupCellOfType:MITActionRowTypeLocation withDetailText:@"6-338"];
        return cell;
    }
    
    if (indexPath.row == 1) {
        MITTitleDescriptionCell *cell = [tableView dequeueReusableCellWithIdentifier:MITTitleDescriptionCellIdentifier];
        [cell setTitle:@"Description" setDescription:@"1\n22\n333\n4444\n55555\n666666\n7777777\n88888888\n999999999"];
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        CGFloat cellHeight = [tableView minimumHeightForCellWithReuseIdentifier:MITActionCellIdentifier atIndexPath:indexPath];
        return cellHeight;
    } else {
    
        MITTitleDescriptionCell *cell = [tableView dequeueReusableCellWithIdentifier:MITTitleDescriptionCellIdentifier];
        [cell setTitle:@"Description" setDescription:@"1\n22\n333\n4444\n55555\n666666\n7777777\n88888888\n999999999"];

        CGRect frame = cell.frame;
        frame.size.width = self.tableView.bounds.size.width;
        cell.contentView.frame = frame;
        CGSize fittingSize = [cell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        return fittingSize.height;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section != 0) {
        return nil;
    }
    
    UIView* const headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITMartyDetailHeaderViewIdentifier];
    
    if ([headerView isKindOfClass:[MITMartyDetailHeaderView class]]) {
        MITMartyDetailHeaderView *detailHeaderView = (MITMartyDetailHeaderView*)headerView;
        [detailHeaderView setTitle: @"Gear Head Combo Lathe Mill Drill"];
        [detailHeaderView setStatus:@"Online"];
    }
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    UIView* const headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITMartyDetailHeaderViewIdentifier];
    
    if ([headerView isKindOfClass:[MITMartyDetailHeaderView class]]) {
        MITMartyDetailHeaderView *detailHeaderView = (MITMartyDetailHeaderView*)headerView;
        [detailHeaderView setTitle: @"Gear Head Combo Lathe Mill Drill"];
        [detailHeaderView setStatus:@"Online"];
        CGRect frame = detailHeaderView.frame;
        frame.size.width = self.tableView.bounds.size.width;
        detailHeaderView.contentView.frame = frame;
        
        CGSize fittingSize = [headerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        return fittingSize.height;
    }
    return 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
