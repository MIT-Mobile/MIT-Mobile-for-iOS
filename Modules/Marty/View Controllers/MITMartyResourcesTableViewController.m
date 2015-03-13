#import "MITMartyResourcesTableViewController.h"
#import "MITMartyModel.h"
#import "MITMobiusResourceTableViewCell.h"
#import "UITableView+DynamicSizing.h"
#import "MITMobiusResourceView.h"

NSString* const MITMartyResourcesTableViewPlaceholderCellIdentifier = @"PlaceholderCell";

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
    [self.tableView registerNib:resourceTableViewCellNib forDynamicCellReuseIdentifier:NSStringFromClass([MITMobiusResourceTableViewCell class])];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MITMartyResourcesTableViewPlaceholderCellIdentifier];
    
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
    NSInteger section = indexPath.section;

    if ([self _isPlaceholderCellAtIndexPath:indexPath]) {
        return nil;
    } else if ([self shouldDisplayPlaceholderCell]) {
        --section;
    }

    NSString *sectionKey = self.buildingSections[section];
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

- (MITMartyResource*)_representedObjectForIndexPath:(NSIndexPath*)indexPath
{
    if ([self _isPlaceholderCellAtIndexPath:indexPath]) {
        return nil;
    } else {
        NSInteger section = indexPath.section;
        if ([self shouldDisplayPlaceholderCell]) {
            --section;
        }
        
        NSString *sectionKey = self.buildingSections[section];
        return self.resourcesByBuilding[sectionKey][indexPath.row];
    }
}

- (NSInteger)_baseIndexForSection:(NSInteger)sectionIndex
{
    if ([self shouldDisplayPlaceholderCell] && sectionIndex == 0) {
        return NSNotFound;
    } else if ([self shouldDisplayPlaceholderCell]) {
        --sectionIndex;
    }


    __block NSInteger baseIndex = 1;
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

#pragma mark Delegate Passthroughs
- (NSIndexPath*)_indexPathForPlaceholderCell
{
    if ([self shouldDisplayPlaceholderCell]) {
        return nil;
    } else {
        return [NSIndexPath indexPathForRow:0 inSection:0];
    }
}

- (BOOL)_isPlaceholderCellAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self shouldDisplayPlaceholderCell]) {
        return (indexPath.section == 0 && indexPath.row == 0);
    } else {
        return NO;
    }
}

- (BOOL)shouldDisplayPlaceholderCell
{
    if ([self.delegate respondsToSelector:@selector(shouldDisplayPlaceholderCellForResourcesTableViewController:)]) {
        return [self.delegate shouldDisplayPlaceholderCellForResourcesTableViewController:self];
    } else {
        return NO;
    }
}

- (CGFloat)heightOfPlaceholderCell
{
    if ([self.delegate respondsToSelector:@selector(heightOfPlaceholderCellForResourcesTableViewController:)]) {
        return [self.delegate heightOfPlaceholderCellForResourcesTableViewController:self];
    } else {
        return 0;
    }
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    __block NSInteger numberOfSections = 0;
    numberOfSections = [self.buildingSections count];

    if ([self shouldDisplayPlaceholderCell]) {
        ++numberOfSections;
    }

    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self shouldDisplayPlaceholderCell] && section == 0) {
        return 1;
    } else {
        if ([self shouldDisplayPlaceholderCell]) {
            --section;
        }
        
        __block NSInteger numberOfRows = 0;
        NSString *sectionKey = self.buildingSections[section];
        NSArray *resources = self.resourcesByBuilding[sectionKey];
        numberOfRows = [resources count];
        
        return numberOfRows;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self shouldDisplayPlaceholderCell] && (section == 0)) {
        return nil;
    } else if ([self shouldDisplayPlaceholderCell]) {
        --section;
    }

    NSString *buildingNumber = self.buildingSections[section];
    return [NSString stringWithFormat:@"Building %@", buildingNumber];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = nil;

    if ([self _isPlaceholderCellAtIndexPath:indexPath]) {
        cellIdentifier = MITMartyResourcesTableViewPlaceholderCellIdentifier;
    } else {
        cellIdentifier = NSStringFromClass([MITMobiusResourceTableViewCell class]);
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    [self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self _isPlaceholderCellAtIndexPath:indexPath]) {
        return [self heightOfPlaceholderCell];
    } else {
        return [tableView minimumHeightForCellWithReuseIdentifier:NSStringFromClass([MITMobiusResourceTableViewCell class]) atIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self _isPlaceholderCellAtIndexPath:indexPath]) {
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.textLabel.text = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        NSAssert([cell isKindOfClass:[MITMobiusResourceTableViewCell class]], @"cell for [%@,%@] is kind of %@, expected %@",cell.reuseIdentifier,indexPath,NSStringFromClass([cell class]),NSStringFromClass([MITMobiusResourceTableViewCell class]));
        
        MITMobiusResourceTableViewCell *resourceCell = (MITMobiusResourceTableViewCell*)cell;
        MITMartyResource *resource = [self _representedObjectForIndexPath:indexPath];

        NSInteger baseIndexForSection = [self _baseIndexForSection:indexPath.section];
        resourceCell.resourceView.index = baseIndexForSection + indexPath.row;
        resourceCell.resourceView.machineName = resource.name;
        resourceCell.resourceView.location = resource.room;
        [resourceCell.resourceView setStatus:MITMobiusResourceStatusOnline withText:resource.status];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self _isPlaceholderCellAtIndexPath:indexPath]) {
        cell.separatorInset = UIEdgeInsetsMake(0, CGRectGetWidth(cell.bounds), 0, 0);
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self _isPlaceholderCellAtIndexPath:indexPath]) {
        if ([self.delegate respondsToSelector:@selector(resourcesTableViewControllerDidSelectPlaceholderCell:)]) {
            [self.delegate resourcesTableViewControllerDidSelectPlaceholderCell:self];
        }
    } else if ([self.delegate respondsToSelector:@selector(resourcesTableViewController:didSelectResource:)]) {
        MITMartyResource *resource = [self _representedObjectForIndexPath:indexPath];
        [self.delegate resourcesTableViewController:self didSelectResource:resource];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.tableView) {
        if ([self.delegate respondsToSelector:@selector(resourcesTableViewController:didScrollToContentOffset:)]) {
            [self.delegate resourcesTableViewController:self didScrollToContentOffset:scrollView.contentOffset];
        }
    }
}

@end
