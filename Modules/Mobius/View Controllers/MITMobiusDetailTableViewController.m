#import "MITMobiusDetailTableViewController.h"
#import "MITActionCell.h"
#import "UITableView+DynamicSizing.h"
#import "MITTitleDescriptionCell.h"
#import "MITMobiusSpecificationsHeader.h"
#import "MITMobiusDetailHeader.h"
#import "MITMobiusModel.h"
#import "MITMapModelController.h"
#import "MITMobiusSegmentedHeader.h"

static NSString * const MITActionCellIdentifier = @"MITActionCellIdentifier";
static NSString * const MITTitleDescriptionCellIdentifier = @"MITTitleDescriptionCellIdentifier";
static NSString * const MITMobiusDetailCellIdentifier = @"MITMobiusDetailCellIdentifier";
static NSString * const MITMobiusSpecificationsHeaderIdentifier = @"MITMobiusSpecificationsHeaderIdentifier";
static NSString * const MITMobiusSegmentedHeaderIdentifier = @"MITMobiusSegmentedHeaderIdentifier";

typedef NS_ENUM(NSInteger, MITMobiusTableViewSection) {
    MITMobiusTableViewSectionSegmented,
};

typedef NS_ENUM(NSInteger, MITMobiusShopDetailsTableViewRows) {
    MITMobiusTableViewRowHoursLabel,
    MITMobiusTableViewRowHours,
    MITMobiusTableViewRowLocation,
    MITMobiusTableViewRowDetails
};

typedef NS_ENUM(NSInteger, MITMobiusSegmentedSections) {
    MITMobiusTableViewSectionShopDetails,
    MITMobiusTableViewSectionSpecs
};

@interface MITMobiusDetailTableViewController() <UITableViewDataSourceDynamicSizing, MITMobiusSegmentedHeaderDelegate>

@property(nonatomic,strong) NSMutableArray *titles;
@property(nonatomic,strong) NSMutableArray *descriptions;
@property(nonatomic,readonly,strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic) NSInteger currentSegementedSection;
@property(nonatomic,strong) NSArray *hours;
@property(nonatomic,strong) NSArray *rowTypes;

@end

@implementation MITMobiusDetailTableViewController
@synthesize managedObjectContext = _managedObjectContext;

- (instancetype)init
{
    self = [self initWithStyle:UITableViewStylePlain];
    if (self) {
        self.currentSegementedSection = 0;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupTableView:self.tableView];
    [self refreshEventRows];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)combineDescriptionsForTitle
{
    self.titles = [[NSMutableArray alloc] init];
    self.descriptions = [[NSMutableArray alloc] init];
    
    for(MITMobiusResourceAttribute *rAttribute in self.resource.attributes) {
        NSString *valueString = nil;
        for (MITMobiusResourceAttributeValue *value in rAttribute.values) {
            if ([valueString length] == 0) {
                valueString = value.value;
            } else {
                valueString = [NSString stringWithFormat:@"%@\n%@",valueString, value.value];
            }
        }
        if (valueString.length != 0) {
            [self.titles addObject:rAttribute.attribute.label];
            [self.descriptions addObject:valueString];
        }
    }
}

- (void)refreshEventRows
{
    NSMutableArray *rowTypes = [NSMutableArray array];
    
    if (self.currentSegementedSection == MITMobiusTableViewSectionShopDetails) {
        if (self.hours.count > 0) {
            [rowTypes addObject:@(MITMobiusTableViewRowHoursLabel)];
        }
        
        [self.hours enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [rowTypes addObject:@(MITMobiusTableViewRowHours)];
        }];
        
        if (self.resource.room) {
            [rowTypes addObject:@(MITMobiusTableViewRowLocation)];
        }
    } else if (self.currentSegementedSection == MITMobiusTableViewSectionSpecs) {
        
        [self.titles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [rowTypes addObject:@(MITMobiusTableViewRowDetails)];
        }];
        
    }
    self.rowTypes = rowTypes;
    [self.tableView reloadData];
}

- (void)setupTableView:(UITableView *)tableView;
{
    tableView.dataSource = self;
    tableView.delegate = self;
    
    [tableView registerNib:[MITActionCell actionCellNib] forDynamicCellReuseIdentifier:MITActionCellIdentifier];
    
    [tableView registerNib:[MITTitleDescriptionCell titleDescriptionCellNib] forDynamicCellReuseIdentifier:MITTitleDescriptionCellIdentifier];
    
    [tableView registerNib:[MITMobiusSpecificationsHeader titleHeaderNib] forHeaderFooterViewReuseIdentifier:MITMobiusSpecificationsHeaderIdentifier];

    [tableView registerNib:[MITMobiusSegmentedHeader segmentedHeaderNib] forHeaderFooterViewReuseIdentifier:MITMobiusSegmentedHeaderIdentifier];

    tableView.tableFooterView = [UIView new];
    
    tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    
    MITMobiusDetailHeader *detailHeader = [[[NSBundle mainBundle]
                     loadNibNamed:@"MITMobiusDetailHeader"
                     owner:self options:nil]
                    firstObject];
    detailHeader.resource = self.resource;
    
    tableView.tableHeaderView = detailHeader;
    [detailHeader setNeedsLayout];
    [detailHeader layoutIfNeeded];
    CGFloat height = [detailHeader systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    //update the header's frame and set it again
    CGRect tableHeaderViewFrame = detailHeader.frame;
    tableHeaderViewFrame.size.height = height;
    detailHeader.frame = tableHeaderViewFrame;
    self.tableView.tableHeaderView = detailHeader;
}

- (NSArray *)hours
{
    return _hours = @[@"a",@"b",@"c"];
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
        [self refreshEventRows];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.rowTypes.count;
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
    NSInteger rowType = [self.rowTypes[indexPath.row] integerValue];
    
    if (rowType == MITMobiusTableViewRowLocation ) {
        MITActionCell *actionCell = (MITActionCell*)cell;
        [actionCell setupCellOfType:MITActionRowTypeLocation withDetailText:self.resource.room];
        
    } else if (rowType == MITMobiusTableViewRowDetails ) {
        MITTitleDescriptionCell *titleDescriptionCell = (MITTitleDescriptionCell*)cell;
        NSString *title = self.titles[indexPath.row];
        NSString *description = self.descriptions[indexPath.row];
        [titleDescriptionCell setTitle:title withDescription:description];
        
    } else if (rowType == MITMobiusTableViewRowHours) {
        MITTitleDescriptionCell *titleDescriptionCell = (MITTitleDescriptionCell*)cell;
        [titleDescriptionCell setTitle:@"mon-fri" withDescription:@"9am - 5pm"];
        
    } else if (rowType == MITMobiusTableViewRowHoursLabel) {
        MITActionCell *actionCell = (MITActionCell*)cell;
        [actionCell setupCellOfType:MITActionRowTypeHours withDetailText:@""];
        actionCell.userInteractionEnabled = NO;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowType = [self.rowTypes[indexPath.row] integerValue];

    if (rowType == MITMobiusTableViewRowLocation ) {
        [MITMapModelController openMapWithUnsanitizedSearchString:self.resource.room];
    }
}

#pragma mark UITableView Data Source/Delegate Helper Methods
- (NSString*)reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSInteger rowType = [self.rowTypes[indexPath.row] integerValue];

    if (self.currentSegementedSection == MITMobiusTableViewSectionShopDetails) {
        if (rowType == MITMobiusTableViewRowLocation) {
            return MITActionCellIdentifier;
        } else if (rowType == MITMobiusTableViewRowHoursLabel) {
            return MITActionCellIdentifier;
        } else if (rowType == MITMobiusTableViewRowHours) {
            return MITTitleDescriptionCellIdentifier;
        }
    } else if (self.currentSegementedSection == MITMobiusTableViewSectionSpecs) {
        return MITTitleDescriptionCellIdentifier;
    }
    return nil;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == MITMobiusTableViewSectionSegmented) {
        UIView* const headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITMobiusSegmentedHeaderIdentifier];
        
        if ([headerView isKindOfClass:[MITMobiusSegmentedHeader class]]) {
            MITMobiusSegmentedHeader *segmentedHeaderView = (MITMobiusSegmentedHeader*)headerView;
            segmentedHeaderView.delegate = self;
            segmentedHeaderView.segmentedControl.selectedSegmentIndex = self.currentSegementedSection;
        }
        
        return headerView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == MITMobiusTableViewSectionSegmented) {
        UIView* const headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITMobiusSegmentedHeaderIdentifier];
        
        if ([headerView isKindOfClass:[MITMobiusSegmentedHeader class]]) {
            MITMobiusSegmentedHeader *segmentedHeaderView = (MITMobiusSegmentedHeader*)headerView;
            CGRect frame = segmentedHeaderView.frame;
            frame.size.width = self.tableView.bounds.size.width;
            segmentedHeaderView.contentView.frame = frame;
            
            CGSize fittingSize = [segmentedHeaderView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
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

#pragma MITMobiusSegmentedHeaderDelegate
- (void)detailSegmentControlAction:(UISegmentedControl *)segmentedControl
{
    self.currentSegementedSection = segmentedControl.selectedSegmentIndex;
    [self refreshEventRows];
}

@end
