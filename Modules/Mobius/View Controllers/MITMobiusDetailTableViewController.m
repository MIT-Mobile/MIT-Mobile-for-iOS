#import "MITMobiusDetailTableViewController.h"
#import "MITActionCell.h"
#import "MITMobiusDetailCell.h"
#import "UITableView+DynamicSizing.h"
#import "MITTitleDescriptionCell.h"
#import "MITMobiusSpecificationsHeader.h"

#import "MITMobiusModel.h"
#import "MITMapModelController.h"

static NSString * const MITActionCellIdentifier = @"MITActionCellIdentifier";
static NSString * const MITTitleDescriptionCellIdentifier = @"MITTitleDescriptionCellIdentifier";
static NSString * const MITMobiusDetailCellIdentifier = @"MITMobiusDetailCellIdentifier";
static NSString * const MITMobiusSpecificationsHeaderIdentifier = @"MITMobiusSpecificationsHeaderIdentifier";

typedef NS_ENUM(NSInteger, MITMobiusTableViewSection) {
    MITMobiusTableViewSectionDetail,
    MITMobiusTableViewSectionLocation,
    MITMobiusTableViewSectionFakeHours,
    MITMobiusTableViewSectionSpecificatons
    
};

@interface MITMobiusDetailTableViewController() <UITableViewDataSourceDynamicSizing>

@property(nonatomic,strong) NSMutableArray *titles;
@property(nonatomic,strong) NSMutableArray *descriptions;
@property(nonatomic,readonly,strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation MITMobiusDetailTableViewController
@synthesize managedObjectContext = _managedObjectContext;

- (instancetype)init
{
    self = [self initWithStyle:UITableViewStylePlain];
    if (self) {

    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)combineDescriptionsForTitle
{
    self.titles = [[NSMutableArray alloc] init];
    self.descriptions = [[NSMutableArray alloc] init];

    for (MITMobiusResourceAttributeValueSet *valueSet in self.resource.attributeValues) {
        NSMutableString *valueString = [[NSMutableString alloc] init];

        for (MITMobiusResourceAttributeValue *value in valueSet.values) {
            if (value.value.length > 0) {
                if (valueString.length > 0) {
                    [valueString appendString:@"\n"];
                }

                [valueString appendString:value.value];
            }
        }

        if (valueString.length > 0) {
            [self.titles addObject:valueSet.label];
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
    
    [tableView registerNib:[MITMobiusDetailCell detailCellNib] forDynamicCellReuseIdentifier:MITMobiusDetailCellIdentifier];
    
    [tableView registerNib:[MITMobiusSpecificationsHeader titleHeaderNib] forHeaderFooterViewReuseIdentifier:MITMobiusSpecificationsHeaderIdentifier];

    tableView.tableFooterView = [UIView new];
    
    tableView.separatorStyle = UITableViewCellSelectionStyleNone;
}

- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:NO];
        managedObjectContext.retainsRegisteredObjects = YES;
        _managedObjectContext = managedObjectContext;
    }

    return _managedObjectContext;
}

- (void)setResource:(MITMobiusResource *)resource
{
    if (![_resource.objectID isEqual:resource.objectID]) {
        if (resource) {
            _resource = (MITMobiusResource*)[self.managedObjectContext objectWithID:resource.objectID];
            [self combineDescriptionsForTitle];
        } else {
            _resource = nil;
            self.descriptions = nil;
            self.titles = nil;
        }

        [self.tableView reloadData];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == MITMobiusTableViewSectionDetail ||
        section == MITMobiusTableViewSectionLocation) {
        return 1;
    } else if (section == MITMobiusTableViewSectionSpecificatons) {
        return [self.titles count];
    } else if (section == MITMobiusTableViewSectionFakeHours) {
        return 2;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    NSAssert(identifier,@"[%@] missing cell reuse identifier in %@",self,NSStringFromSelector(_cmd));
   
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
    if ([cell isKindOfClass:[MITMobiusDetailCell class]]) {
        MITMobiusDetailCell *detailCell = (MITMobiusDetailCell*)cell;
        [detailCell setTitle: self.resource.name];
        [detailCell setStatus:self.resource.status];

    } else if ([cell isKindOfClass:[MITActionCell class]] && indexPath.section == MITMobiusTableViewSectionLocation) {
        MITActionCell *actionCell = (MITActionCell*)cell;
        [actionCell setupCellOfType:MITActionRowTypeLocation withDetailText:self.resource.room];

    } else if ([cell isKindOfClass:[MITTitleDescriptionCell class]] && indexPath.section == MITMobiusTableViewSectionSpecificatons) {
        MITTitleDescriptionCell *titleDescriptionCell = (MITTitleDescriptionCell*)cell;
        NSString *title = self.titles[indexPath.row];
        NSString *description = self.descriptions[indexPath.row];
        [titleDescriptionCell setTitle:title withDescription:description];
 
    } else if ([cell isKindOfClass:[MITTitleDescriptionCell class]] && indexPath.section == MITMobiusTableViewSectionFakeHours) {
        MITTitleDescriptionCell *titleDescriptionCell = (MITTitleDescriptionCell*)cell;
        if (indexPath.row == 0) {
            [titleDescriptionCell setTitle:@"mon-fri" withDescription:@"9am - 5pm"];
        } else {
            [titleDescriptionCell setTitle:@"sat-sun" withDescription:@"closed"];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == MITMobiusTableViewSectionLocation) {
        [MITMapModelController openMapWithUnsanitizedSearchString:self.resource.room];
    }
}

#pragma mark UITableView Data Source/Delegate Helper Methods
- (NSString*)reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == MITMobiusTableViewSectionDetail) {
        return MITMobiusDetailCellIdentifier;
    } else if (indexPath.section == MITMobiusTableViewSectionLocation) {
        return MITActionCellIdentifier;
    } else if (indexPath.section == MITMobiusTableViewSectionFakeHours) {
        return MITTitleDescriptionCellIdentifier;;
    } else if (indexPath.section == MITMobiusTableViewSectionSpecificatons) {
        return MITTitleDescriptionCellIdentifier;
    }
    
    return nil;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == MITMobiusTableViewSectionSpecificatons) {
        UIView* const headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITMobiusSpecificationsHeaderIdentifier];
        
        if ([headerView isKindOfClass:[MITMobiusSpecificationsHeader class]]) {
            MITMobiusSpecificationsHeader *specificationsHeaderView = (MITMobiusSpecificationsHeader*)headerView;
            specificationsHeaderView.titleLabel.text = @"Specifications";
        }
        return headerView;
        
    } else if (section == MITMobiusTableViewSectionFakeHours) {
        UIView* const headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITMobiusSpecificationsHeaderIdentifier];
        
        if ([headerView isKindOfClass:[MITMobiusSpecificationsHeader class]]) {
            MITMobiusSpecificationsHeader *specificationsHeaderView = (MITMobiusSpecificationsHeader*)headerView;
            specificationsHeaderView.titleLabel.text = @"Hours";
        }
        
        return headerView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == MITMobiusTableViewSectionSpecificatons || section == MITMobiusTableViewSectionFakeHours) {
        UIView* const headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITMobiusSpecificationsHeaderIdentifier];
        
        if ([headerView isKindOfClass:[MITMobiusSpecificationsHeader class]]) {
            MITMobiusSpecificationsHeader *specificationsHeaderView = (MITMobiusSpecificationsHeader*)headerView;
            if (section == MITMobiusTableViewSectionFakeHours) {
                specificationsHeaderView.titleLabel.text = @"Specifications";
            } else {
                specificationsHeaderView.titleLabel.text = @"Fake";
            }
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
