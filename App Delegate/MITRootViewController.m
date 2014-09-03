#import "MITRootViewController.h"
#import "MITAdditions.h"

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

}

- (void)setModules:(NSArray *)modules animated:(BOOL)animated
{
    if (![_modules isEqualToArray:modules]) {
        MITModule *selectedModule = self.selectedModule;
        NSIndexPath *selectedIndexPath = self.selectedIndexPath;

        _modules = [modules copy];

        [self didUpdateModules:YES];
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    if ([self.modules count] > selectedIndex) {
        NSIndexPath *indexPath = [self indexPathForModule:self.modules[selectedIndex]];
        self.selectedIndexPath = indexPath;
    }
}

- (NSUInteger)selectedIndex
{
    return self.selectedIndexPath.row;
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

- (MITDrawerItem*)_drawerItemForViewControllerAtIndex:(NSUInteger)index
{
    UIViewController *viewController = self.viewControllers[index];

    if (!viewController.drawerItem) {
        return [[MITDrawerItem alloc] initWithTitle:viewController.title image:nil];
    } else {
        return viewController.drawerItem;
    }
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

#pragma mark - Delegation
#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.viewControllers count];
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
        MITDrawerItem *drawerItem = [self _drawerItemForViewControllerAtIndex:indexPath.row];

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

- (UIViewController*)viewControllerForRowAtIndexPath:(NSIndexPath*)indexPath
{
    indexPath = [NSIndexPath indexPathWithIndexPath:indexPath];
    return self.viewControllers[indexPath.row];
}

#pragma mark UITableViewDelegate
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    indexPath = [NSIndexPath indexPathWithIndexPath:indexPath];

    UIViewController *viewController = [self viewControllerForRowAtIndexPath:indexPath];
    if (viewController == self.selectedViewController) {
        return;
    }

    NSIndexPath *previouslySelectedIndexPath = [NSIndexPath indexPathForRow:self.selectedIndex inSection:0];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:previouslySelectedIndexPath];
    cell.contentView.backgroundColor = self.view.backgroundColor;

    cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.contentView.backgroundColor = self.view.tintColor;
    self.selectedIndex = indexPath.row;
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
