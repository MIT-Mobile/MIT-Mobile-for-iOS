#import "MITMartyDetailTableViewController.h"
#import "MITActionCell.h"
#import "MITMartyDetailCell.h"
#import "UITableView+DynamicSizing.h"
#import "MITTitleDescriptionCell.h"
#import "MITMartySpecificationsHeader.h"

#import "MITMartyTemplateAttribute.h"
#import "MITMartyResourceAttribute.h"
#import "MITMartyResourceAttributeValue.h"

static NSString * const MITActionCellIdentifier = @"MITActionCellIdentifier";
static NSString * const MITTitleDescriptionCellIdentifier = @"MITTitleDescriptionCellIdentifier";
static NSString * const MITMartyDetailCellIdentifier = @"MITMartyDetailCellIdentifier";
static NSString * const MITMartySpecificationsHeaderIdentifier = @"MITMartySpecificationsHeaderIdentifier";

@interface MITMartyDetailTableViewController() <UITableViewDataSourceDynamicSizing>

@end

@implementation MITMartyDetailTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[MITActionCell actionCellNib] forDynamicCellReuseIdentifier:MITActionCellIdentifier];

    [self.tableView registerNib:[MITTitleDescriptionCell titleDescriptionCellNib] forDynamicCellReuseIdentifier:MITTitleDescriptionCellIdentifier];

    [self.tableView registerNib:[MITMartyDetailCell detailCellNib] forDynamicCellReuseIdentifier:MITMartyDetailCellIdentifier];
    
    [self.tableView registerNib:[MITMartySpecificationsHeader titleHeaderNib] forHeaderFooterViewReuseIdentifier:MITMartySpecificationsHeaderIdentifier];
    
    self.tableView.tableFooterView = [UIView new];
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
        return [self.resource.attributes count];
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
        [detailCell setTitle: self.resource.name];
        [detailCell setStatus:self.resource.status];

    } else if ([cell isKindOfClass:[MITActionCell class]]) {
        MITActionCell *actionCell = (MITActionCell*)cell;
        [actionCell setupCellOfType:MITActionRowTypeLocation withDetailText:self.resource.room];

    } else if ([cell isKindOfClass:[MITTitleDescriptionCell class]]) {
        MITTitleDescriptionCell *titleDescriptionCell = (MITTitleDescriptionCell*)cell;

        MITMartyResourceAttribute *rAttribute = self.resource.attributes[indexPath.row];
        
        NSString *valueString = [[NSString alloc] init];
        
        for (MITMartyResourceAttributeValue *value in rAttribute.values) {
            if ([value.value length] != 0) {
                if ([valueString length] == 0) {
                    valueString = value.value;
                } else {
                    valueString = [NSString stringWithFormat:@"%@\n%@",valueString, value.value];
                }
            }
        }
        
        [titleDescriptionCell setTitle:rAttribute.attribute.label setDescription:valueString];
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
    if (section == 2) {
        UIView* const headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITMartySpecificationsHeaderIdentifier];
        
        if ([headerView isKindOfClass:[MITMartySpecificationsHeader class]]) {
            MITMartySpecificationsHeader *specificationsHeaderView = (MITMartySpecificationsHeader*)headerView;
            specificationsHeaderView.titleLabel.text = @"Specifications";
        }
        
        return headerView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 2) {
        UIView* const headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITMartySpecificationsHeaderIdentifier];
        
        if ([headerView isKindOfClass:[MITMartySpecificationsHeader class]]) {
            MITMartySpecificationsHeader *specificationsHeaderView = (MITMartySpecificationsHeader*)headerView;
            specificationsHeaderView.titleLabel.text = @"Specifications";
            
            CGRect frame = specificationsHeaderView.frame;
            frame.size.width = self.tableView.bounds.size.width;
            specificationsHeaderView.contentView.frame = frame;
            
            CGSize fittingSize = [specificationsHeaderView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
            return fittingSize.height;
        }
    }
    return 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
