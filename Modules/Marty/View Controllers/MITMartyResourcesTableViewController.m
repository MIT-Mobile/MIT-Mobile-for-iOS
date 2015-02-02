#import "MITMartyResourcesTableViewController.h"
#import "MITMartyModel.h"
#import "MITMartyResourceTableViewCell.h"
#import "UITableView+DynamicSizing.h"

@interface MITMartyResourcesTableViewController () <UITableViewDataSourceDynamicSizing>
@property(nonatomic,readonly,strong) NSManagedObjectContext *managedObjectContext;

@property(nonatomic,readonly,strong) NSArray *buildingSections;
@property(nonatomic,readonly,strong) NSDictionary *resourcesByBuilding;
@end

@implementation MITMartyResourcesTableViewController
@synthesize resourcesByBuilding = _resourcesByBuilding;
@synthesize buildingSections = _buildingSections;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:NO];
    
    UINib *resourceTableViewCellNib = [UINib nibWithNibName:@"MITMartyResourceTableViewCell" bundle:nil];
    [self.tableView registerNib:resourceTableViewCellNib forDynamicCellReuseIdentifier:NSStringFromClass([MITMartyResourceTableViewCell class])];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setResources:(NSArray *)resources
{
    if (![_resources isEqualToArray:resources]) {
        [self.managedObjectContext reset];
        _resources = [self.managedObjectContext transferManagedObjects:resources];
        [self reloadData];
    }
}

- (void)reloadData
{
    [self.managedObjectContext performBlock:^{
        _buildingSections = nil;
        _resourcesByBuilding = nil;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadData];
        }];
    }];
}

- (MITMartyResource*)selectedResource
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSString *sectionKey = self.buildingSections[indexPath.section];
    NSManagedObjectID *resourceObjectID = [self.resourcesByBuilding[sectionKey][indexPath.row] objectID];
    
    MITMartyResource *resource = (MITMartyResource*)[[[MITCoreDataController defaultController] mainQueueContext] objectWithID:resourceObjectID];
    return resource;
}

- (NSArray*)buildingSections
{
    if (!_buildingSections) {
        [self.managedObjectContext performBlockAndWait:^{
            NSMutableOrderedSet *buildings = [[NSMutableOrderedSet alloc] init];
            [self.resources enumerateObjectsUsingBlock:^(MITMartyResource *resource, NSUInteger idx, BOOL *stop) {
                NSString *building = [[resource.room componentsSeparatedByString:@"-"] firstObject];
                [buildings addObject:building];
            }];
            
            [buildings sortUsingComparator:^NSComparisonResult(NSString *location1, NSString *location2) {
                NSArray *locationComponents1 = [location1 componentsSeparatedByString:@"-"];
                NSArray *locationComponents2 = [location2 componentsSeparatedByString:@"-"];
                
                NSStringCompareOptions compareOptions = (NSCaseInsensitiveSearch | NSNumericSearch);
                
                NSString *building1 = [locationComponents1 firstObject];
                NSString *building2 = [locationComponents2 firstObject];
                NSComparisonResult buildingResult = [building1 compare:building2 options:compareOptions];
                if (buildingResult == NSOrderedSame) {
                    NSString *room1 = [locationComponents1 lastObject];
                    NSString *room2 = [locationComponents2 lastObject];
                    
                    return [room1 compare:room2 options:compareOptions];
                } else {
                    return buildingResult;
                }
            }];
            
            _buildingSections = [buildings array];
        }];
    }
    
    return _buildingSections;
}

- (NSDictionary*)resourcesByBuilding
{
    if (!_resourcesByBuilding) {
        [self.managedObjectContext performBlockAndWait:^{
            NSMutableDictionary *resourcesByBuilding = [[NSMutableDictionary alloc] init];
            [self.resources enumerateObjectsUsingBlock:^(MITMartyResource *resource, NSUInteger idx, BOOL *stop) {
                NSString *building = [[resource.room componentsSeparatedByString:@"-"] firstObject];
                
                NSMutableArray *resources = resourcesByBuilding[building];
                if (!resources) {
                    resources = [[NSMutableArray alloc] init];
                    resourcesByBuilding[building] = resources;
                }
                
                [resources addObject:resource];
            }];
            
            _resourcesByBuilding = resourcesByBuilding;
        }];
    }
    
    return _resourcesByBuilding;
}

- (NSInteger)_baseIndexForSection:(NSInteger)sectionIndex
{
    __block NSInteger baseIndex = 0;
    [self.buildingSections enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
        if (idx < sectionIndex) {
            NSArray *resources = self.resourcesByBuilding[key];
            baseIndex += [resources count];
        } else {
            (*stop) = YES;
        }
    }];
    
    return baseIndex;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    __block NSInteger numberOfSections = 0;
    numberOfSections = [self.buildingSections count];
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    __block NSInteger numberOfRows = 0;
    NSString *sectionKey = self.buildingSections[section];
    NSArray *resources = self.resourcesByBuilding[sectionKey];
    numberOfRows = [resources count];
    
    return numberOfRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = NSStringFromClass([MITMartyResourceTableViewCell class]);
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    [self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView minimumHeightForCellWithReuseIdentifier:NSStringFromClass([MITMartyResourceTableViewCell class]) atIndexPath:indexPath];
}


- (void)tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSAssert([cell isKindOfClass:[MITMartyResourceTableViewCell class]], @"cell for [%@,%@] is kind of %@, expected %@",cell.reuseIdentifier,indexPath,NSStringFromClass([cell class]),NSStringFromClass([MITMartyResourceTableViewCell class]));
    
    MITMartyResourceTableViewCell *resourceCell = (MITMartyResourceTableViewCell*)cell;
    
    NSInteger baseIndexForSection = [self _baseIndexForSection:indexPath.section];
    NSString *sectionKey = self.buildingSections[indexPath.section];
    MITMartyResource *resource = self.resourcesByBuilding[sectionKey][indexPath.row];
    
    resourceCell.index = baseIndexForSection + indexPath.row;
    resourceCell.machineName = resource.name;
    resourceCell.location = resource.room;
    [resourceCell setStatus:MITMartyResourceStatusOnline withText:resource.status];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate) {
        [self.delegate resourcesTableViewController:self didSelectResource:self.selectedResource];
    }
}

@end
