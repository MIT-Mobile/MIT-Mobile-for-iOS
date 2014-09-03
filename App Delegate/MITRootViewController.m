#import "MITRootViewController.h"
#import "MITAdditions.h"
#import "MITModule.h"

static NSString* const MITDrawerReuseIdentifierItemCell = @"DrawerItemCellReuseIdentifier";
static NSString* const MITRootLogoHeaderReuseIdentifier = @"RootLogoHeaderReuseIdentifier";
static NSUInteger const MITModuleSectionIndex = 0;

@interface MITRootViewController () <UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,readonly) UITableViewController *tableViewController;
@property (nonatomic,strong) NSIndexPath *selectedIndexPath;
@end

@implementation MITRootViewController
@dynamic tableViewController;
@dynamic selectedIndex;
@dynamic selectedModule;

- (instancetype)initWithModules:(NSArray *)modules
{
    NSAssert([modules count] > 0,@"there must be at least 1 module");

    UIViewController *blankTopViewController = [[UIViewController alloc] init];
    self = [super initWithTopViewController:blankTopViewController];

    if (self) {
        _modules = [modules copy];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _setupTableViewController];

    self.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGestureTapping;

    NSIndexPath *indexPath = [self _indexPathForModule:[self.modules firstObject]];
    self.selectedIndexPath = indexPath;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!([self.modules count] > 0)) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"drawer view controller must have at least 1 view controller added before being presented" userInfo:nil];
    }
}

#pragma mark Properties
- (UITableViewController*)tableViewController
{
    if ([self.underLeftViewController isKindOfClass:[UITableViewController class]]) {
        return (UITableViewController*)self.underLeftViewController;
    } else {
        return nil;
    }
}

- (void)setModules:(NSArray *)modules
{
    [self setModules:modules animated:NO];
}

- (void)setModules:(NSArray *)modules animated:(BOOL)animated
{
    if (![_modules isEqualToArray:modules]) {
        _modules = [modules filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(MITModule *module, NSDictionary *bindings) {
            UIUserInterfaceIdiom interfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
            if ([module supportsUserInterfaceIdiom:interfaceIdiom]) {
                return YES;
            } else {
                return NO;
            }
        }]];

        [self didUpdateModules:YES];
    }
}

- (void)didUpdateModules:(BOOL)animated
{
    MITModule *selectedModule = self.selectedModule;
    NSUInteger selectedIndex = self.selectedIndex;

    NSIndexPath *moduleIndexPath = [self _indexPathForModule:selectedModule];
    if (!moduleIndexPath) {
        moduleIndexPath = [self _indexPathForModuleAtIndex:selectedIndex];
    }

    if (moduleIndexPath) {
        self.selectedIndexPath = moduleIndexPath;
    } else {
        self.selectedModule = [self.modules firstObject];
    }

}

- (NSUInteger)selectedIndex
{
    MITModule *module = self.selectedModule;
    return [self _indexForModule:module];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    NSIndexPath *selectedIndexPath = [self _indexPathForModuleAtIndex:selectedIndex];
    if (selectedIndexPath) {
        self.selectedIndexPath = selectedIndexPath;
    }
}

- (MITModule*)selectedModule
{
    return [self _moduleForIndexPath:self.selectedIndexPath];
}

- (void)setSelectedModule:(MITModule *)selectedModule
{
    NSIndexPath *selectedIndexPath = [self _indexPathForModule:selectedModule];
    if (selectedIndexPath) {
        self.selectedIndexPath = selectedIndexPath;
    }
}

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath
{
    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexPath:selectedIndexPath];
    if (![_selectedIndexPath isEqual:indexPath]) {
        _selectedIndexPath = indexPath;

        MITModule *module = self.selectedModule;
        self.topViewController = [module homeViewController];
        [self resetTopViewAnimated:YES];
    }
}

- (id<UIViewControllerTransitionCoordinator>)transitionCoordinator
{
    return nil;
}

#pragma mark Private
- (void)_setupTableViewController {
    if (self.tableViewController) {
        UITableViewController *tableViewController = self.tableViewController;
        [tableViewController.tableView registerNib:[UINib nibWithNibName:@"MITLogoReusableHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:MITRootLogoHeaderReuseIdentifier];
        tableViewController.tableView.delegate = self;
        tableViewController.tableView.dataSource = self;
    }
}

- (MITDrawerItem*)_drawerItemForModuleAtIndexPath:(NSIndexPath*)indexPath
{
    MITModule *module = [self _moduleForIndexPath:indexPath];
    UIViewController *viewController = [module homeViewController];

    if (!viewController.drawerItem) {
        MITDrawerItem *drawerItem = [[MITDrawerItem alloc] initWithTitle:module.shortName image:module.springboardIcon];
        viewController.drawerItem = drawerItem;
        return drawerItem;
    } else {
        return viewController.drawerItem;
    }
}

- (MITModule*)_moduleForIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == MITModuleSectionIndex) {
        return self.modules[indexPath.row];
    } else {
        return nil;
    }
}

- (UIViewController*)_viewControllerForIndexPath:(NSIndexPath*)indexPath
{
    MITModule *module = [self _moduleForIndexPath:indexPath];
    return module.homeViewController;
}

- (NSIndexPath*)_indexPathForModule:(MITModule*)module
{
    NSUInteger index = [self.modules indexOfObject:module];

    if (index == NSNotFound) {
        return nil;
    } else {
        return [NSIndexPath indexPathForRow:index inSection:MITModuleSectionIndex];
    }
}

- (NSIndexPath*)_indexPathForModuleAtIndex:(NSUInteger)moduleIndex
{
    if (moduleIndex >= [self.modules count]) {
        return nil;
    } else {
        return [NSIndexPath indexPathForRow:moduleIndex inSection:MITModuleSectionIndex];
    }
}

- (NSUInteger)_indexForModule:(MITModule*)module
{
    return [self.modules indexOfObject:module];
}

#pragma mark - Delegation
#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.modules count];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MITDrawerReuseIdentifierItemCell forIndexPath:indexPath];

    if ([cell isKindOfClass:[UITableViewCell class]]) {
        MITDrawerItem *drawerItem = [self _drawerItemForModuleAtIndexPath:indexPath];

        if (indexPath.row == self.selectedIndex) {
            cell.imageView.image = drawerItem.selectedImage;
            cell.contentView.backgroundColor = self.view.tintColor;
        } else {
            cell.imageView.image = drawerItem.image;
            cell.contentView.backgroundColor = self.view.backgroundColor;
        }

        cell.textLabel.text = drawerItem.title;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 100.;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        UITableViewHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITRootLogoHeaderReuseIdentifier];
        return headerView;
    } else {
        return nil;
    }
}

#pragma mark UITableViewDelegate
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITModule *module = [self _moduleForIndexPath:indexPath];
    if (self.selectedModule == module) {
        return;
    } else {
        NSIndexPath *selectedIndexPath = self.selectedIndexPath;
        self.selectedIndexPath = indexPath;
        [tableView reloadRowsAtIndexPaths:@[selectedIndexPath,indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    UIView *headerView = [self.tableViewController.tableView headerViewForSection:0];
    if (headerView) {
        if (scrollView.contentOffset.y < 0) {
            headerView.layer.transform = CATransform3DMakeTranslation(0, -scrollView.contentOffset.y, 0);
        } else {
            headerView.layer.transform = CATransform3DIdentity;
        }
    }
}

@end
