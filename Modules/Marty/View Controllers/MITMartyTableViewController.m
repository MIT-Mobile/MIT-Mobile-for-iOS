#import "MITMartyTableViewController.h"
#import "MITActionCell.h"
#import "MITMartyDetailCell.h"
#import "UITableView+DynamicSizing.h"
#import "MITTitleDescriptionCell.h"

static NSString * const MITActionCellIdentifier = @"MITActionCellIdentifier";
static NSString * const MITTitleDescriptionCellIdentifier = @"MITTitleDescriptionCellIdentifier";
static NSString * const MITMartyDetailCellIdentifier = @"MITMartyDetailCellIdentifier";

@interface MITMartyTableViewController() <UITableViewDataSource, UITableViewDelegate, UITableViewDataSourceDynamicSizing>

//Test data
@property (nonatomic, strong) NSArray *specificationsTitle;
@property (nonatomic, strong) NSArray *specificationsDescription;

@end

@implementation MITMartyTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[MITActionCell actionCellNib] forDynamicCellReuseIdentifier:MITActionCellIdentifier];

    [self.tableView registerNib:[MITTitleDescriptionCell titleDescriptionCellNib] forDynamicCellReuseIdentifier:MITTitleDescriptionCellIdentifier];

    [self.tableView registerNib:[MITMartyDetailCell detailCellNib] forDynamicCellReuseIdentifier:MITMartyDetailCellIdentifier];
    
    [self setup];
}

- (void)setup
{
    self.specificationsTitle = @[@"Name", @"Description", @"Model"];
    self.specificationsDescription = @[@"Gear Head Combo Lathe Mill Drill", @"This is a tool that is a tool that makes a tool which creates a tool which tests the cell resizing thing of creating a resizable cell that does something about a tool", @"A22"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0 || section == 1) {
        return 1;
    } else if (section == 2) {
        return [self.specificationsDescription count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    NSAssert(identifier,@"[%@] missing cell reuse identifier in %@",self,NSStringFromSelector(_cmd));
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
    
    if (indexPath.section == 0) {
        MITMartyDetailCell *detailCell = [tableView dequeueReusableCellWithIdentifier:MITMartyDetailCellIdentifier];
        [detailCell setTitle: @"Gear Head Combo Lathe Mill Drill"];
        [detailCell setStatus:@"Online"];
        return detailCell;
        
    }
    if (indexPath.section == 1) {
        MITActionCell *cell = [tableView dequeueReusableCellWithIdentifier:MITActionCellIdentifier];
        [cell setupCellOfType:MITActionRowTypeLocation withDetailText:@"6-338"];
        return cell;
    }
    
    if (indexPath.section == 2) {
        MITTitleDescriptionCell *cell = [tableView dequeueReusableCellWithIdentifier:MITTitleDescriptionCellIdentifier];
        [cell setTitle:self.specificationsTitle[indexPath.row] setDescription:self.specificationsDescription[indexPath.row]];
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    CGFloat cellHeight = [tableView minimumHeightForCellWithReuseIdentifier:reuseIdentifier atIndexPath:indexPath];
    return cellHeight;
}

#pragma mark UITableViewDataSourceDynamicSizing
- (void)tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([cell isKindOfClass:[MITMartyDetailCell class]]) {
        MITMartyDetailCell *detailCell = (MITMartyDetailCell*)cell;
        [detailCell setTitle: @"Gear Head Combo Lathe Mill Drill"];
        [detailCell setStatus:@"Online"];
    } else if ([cell isKindOfClass:[MITActionCell class]]) {
        MITActionCell *actionCell = (MITActionCell*)cell;
        [actionCell setupCellOfType:MITActionRowTypeLocation withDetailText:@"6-338"];

    } else if ([cell isKindOfClass:[MITTitleDescriptionCell class]]) {
        MITTitleDescriptionCell *titleDescriptionCell = (MITTitleDescriptionCell*)cell;
        [titleDescriptionCell setTitle:self.specificationsTitle[indexPath.row] setDescription:self.specificationsDescription[indexPath.row]];
    }
}

#pragma mark UITableView Data Source/Delegate Helper Methods
- (NSString*)reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == 0) {
        return MITMartyDetailCellIdentifier;
    } else if (indexPath.section == 1) {
        return MITActionCellIdentifier;
    } else if (indexPath.section == 2) {
        return MITTitleDescriptionCellIdentifier;
    }

    return nil;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
