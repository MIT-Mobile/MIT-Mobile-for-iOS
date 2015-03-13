#import "MITMartyDetailTableViewController.h"
#import "MITActionCell.h"
#import "MITMobiusDetailCell.h"
#import "UITableView+DynamicSizing.h"
#import "MITTitleDescriptionCell.h"
#import "MITMobiusSpecificationsHeader.h"

#import "MITMartyModel.h"

static NSString * const MITActionCellIdentifier = @"MITActionCellIdentifier";
static NSString * const MITTitleDescriptionCellIdentifier = @"MITTitleDescriptionCellIdentifier";
static NSString * const MITMartyDetailCellIdentifier = @"MITMartyDetailCellIdentifier";
static NSString * const MITMartySpecificationsHeaderIdentifier = @"MITMartySpecificationsHeaderIdentifier";

typedef NS_ENUM(NSInteger, MITMartyTableViewSection) {
    MITMartyTableViewSectionDetail,
    MITMartyTableViewSectionLocation,
    MITMartyTableViewSectionFakeHours,
    MITMartyTableViewSectionSpecificatons
    
};

@interface MITMartyDetailTableViewController() <UITableViewDataSourceDynamicSizing>

//Temporary fix for remove blank description rows
@property(nonatomic,strong) NSMutableArray *titles;
@property(nonatomic,strong) NSMutableArray *descriptions;
@property(nonatomic,readonly,strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation MITMartyDetailTableViewController
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


- (void)removeBlankDescriptionsFromTitleDescriptionPairs
{
    self.titles = [[NSMutableArray alloc] init];
    self.descriptions = [[NSMutableArray alloc] init];
    
    for(MITMartyResourceAttribute *rAttribute in self.resource.attributes) {
        NSString *valueString = nil;
        for (MITMartyResourceAttributeValue *value in rAttribute.values) {
            NSString *trimmedValue = [value.value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([trimmedValue length] != 0) {
                if ([valueString length] == 0) {
                    valueString = trimmedValue;
                } else {
                    valueString = [NSString stringWithFormat:@"%@\n%@",valueString, trimmedValue];
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
    
    [tableView registerNib:[MITMobiusDetailCell detailCellNib] forDynamicCellReuseIdentifier:MITMartyDetailCellIdentifier];
    
    [tableView registerNib:[MITMobiusSpecificationsHeader titleHeaderNib] forHeaderFooterViewReuseIdentifier:MITMartySpecificationsHeaderIdentifier];

    tableView.tableFooterView = [UIView new];
    
    tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    tableView.allowsSelection = NO;
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

- (void)setResource:(MITMartyResource *)resource
{
    if (![_resource.objectID isEqual:resource.objectID]) {
        if (resource) {
            _resource = (MITMartyResource*)[self.managedObjectContext objectWithID:resource.objectID];
            [self removeBlankDescriptionsFromTitleDescriptionPairs];
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
    if (section == MITMartyTableViewSectionDetail ||
        section == MITMartyTableViewSectionLocation) {
        return 1;
    } else if (section == MITMartyTableViewSectionSpecificatons) {
        return [self.titles count];
    } else if (section == MITMartyTableViewSectionFakeHours) {
        return 2;
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
    if ([cell isKindOfClass:[MITMobiusDetailCell class]]) {
        MITMobiusDetailCell *detailCell = (MITMobiusDetailCell*)cell;
        [detailCell setTitle: self.resource.name];
        [detailCell setStatus:self.resource.status];

    } else if ([cell isKindOfClass:[MITActionCell class]]) {
        MITActionCell *actionCell = (MITActionCell*)cell;
        [actionCell setupCellOfType:MITActionRowTypeLocation withDetailText:self.resource.room];

    } else if ([cell isKindOfClass:[MITTitleDescriptionCell class]] && indexPath.section == MITMartyTableViewSectionSpecificatons) {
        MITTitleDescriptionCell *titleDescriptionCell = (MITTitleDescriptionCell*)cell;

        NSString *title = self.titles[indexPath.row];
        NSString *description = self.descriptions[indexPath.row];
        [titleDescriptionCell setTitle:title withDescription:description];
    } else if ([cell isKindOfClass:[MITTitleDescriptionCell class]] && indexPath.section == MITMartyTableViewSectionFakeHours) {
        MITTitleDescriptionCell *titleDescriptionCell = (MITTitleDescriptionCell*)cell;
        
        
        if (indexPath.row == 0) {
            [titleDescriptionCell setTitle:@"mon-fri" withDescription:@"9am - 5pm"];
        } else {
            [titleDescriptionCell setTitle:@"sat-sun" withDescription:@"closed"];
        }

    }
}

#pragma mark UITableView Data Source/Delegate Helper Methods
- (NSString*)reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == MITMartyTableViewSectionDetail) {
        return MITMartyDetailCellIdentifier;
    } else if (indexPath.section == MITMartyTableViewSectionLocation) {
        return MITActionCellIdentifier;
    } else if (indexPath.section == MITMartyTableViewSectionFakeHours) {
        return MITTitleDescriptionCellIdentifier;;
    } else if (indexPath.section == MITMartyTableViewSectionSpecificatons) {
        return MITTitleDescriptionCellIdentifier;
    }
    
    return nil;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == MITMartyTableViewSectionSpecificatons) {
        UIView* const headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITMartySpecificationsHeaderIdentifier];
        
        if ([headerView isKindOfClass:[MITMobiusSpecificationsHeader class]]) {
            MITMobiusSpecificationsHeader *specificationsHeaderView = (MITMobiusSpecificationsHeader*)headerView;
            specificationsHeaderView.titleLabel.text = @"Specifications";
        }
        return headerView;
        
    } else if (section == MITMartyTableViewSectionFakeHours) {
        UIView* const headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITMartySpecificationsHeaderIdentifier];
        
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
    if (section == MITMartyTableViewSectionSpecificatons || section == MITMartyTableViewSectionFakeHours) {
        UIView* const headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITMartySpecificationsHeaderIdentifier];
        
        if ([headerView isKindOfClass:[MITMobiusSpecificationsHeader class]]) {
            MITMobiusSpecificationsHeader *specificationsHeaderView = (MITMobiusSpecificationsHeader*)headerView;
            if (section == MITMartyTableViewSectionFakeHours) {
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
