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

//Temporary fix for remove blank description rows
@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableArray *descriptions;

@end

@implementation MITMartyDetailTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupTableView:self.tableView];
    
    [self removeBlankDescriptionsFromTitleDescriptionPairs];
}

- (void)removeBlankDescriptionsFromTitleDescriptionPairs
{
    self.titles = [[NSMutableArray alloc] init];
    self.descriptions = [[NSMutableArray alloc] init];
    
    for(MITMartyResourceAttribute *rAttribute in self.resource.attributes) {
        NSString *valueString = nil;
        for (MITMartyResourceAttributeValue *value in rAttribute.values) {
            if ([value.value length] != 0) {
                if ([valueString length] == 0) {
                    valueString = value.value;
                } else {
                    valueString = [NSString stringWithFormat:@"%@\n%@",valueString, value.value];
                }
            }
        }
        if (valueString.length != 0) {
            [self.titles addObject:rAttribute.attribute.label];
            [self.descriptions addObject:valueString];
        }
    }
    
}

- (void)setupTableView:(UITableView *)tableView;
{
    tableView.dataSource = self;
    tableView.delegate = self;
    
    [tableView registerNib:[MITActionCell actionCellNib] forDynamicCellReuseIdentifier:MITActionCellIdentifier];
    
    [tableView registerNib:[MITTitleDescriptionCell titleDescriptionCellNib] forDynamicCellReuseIdentifier:MITTitleDescriptionCellIdentifier];
    
    [tableView registerNib:[MITMartyDetailCell detailCellNib] forDynamicCellReuseIdentifier:MITMartyDetailCellIdentifier];
    
    [tableView registerNib:[MITMartySpecificationsHeader titleHeaderNib] forHeaderFooterViewReuseIdentifier:MITMartySpecificationsHeaderIdentifier];
    
    tableView.tableFooterView = [UIView new];
    
    tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    tableView.allowsSelection = NO;
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
        return [self.titles count];
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

        NSString *title = self.titles[indexPath.row];
        NSString *description = self.descriptions[indexPath.row];
        [titleDescriptionCell setTitle:title withDescription:description];
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
