#import "MITRootViewController.h"
#import "MITAdditions.h"

static NSString* const MITDrawerReuseIdentifierItemCell = @"DrawerItemCellReuseIdentifier";
static NSString* const MITRootLogoHeaderReuseIdentifier = @"RootLogoHeaderReuseIdentifier";

@interface MITRootViewController () <UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,readonly) UITableViewController *tableViewController;
@end

@implementation MITRootViewController
@dynamic tableViewController;

- (instancetype)initWithViewControllers:(NSArray *)viewControllers
{
    NSAssert([viewControllers count] > 0,@"view controller must have at least 1 child view controller");

    UIViewController *firstViewController = [viewControllers firstObject];
    self = [super initWithTopViewController:firstViewController];

    if (self) {
        _viewControllers = [viewControllers copy];
        _selectedIndex = 0;
        _selectedViewController = firstViewController;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupTableViewController];
}

- (void)setupTableViewController {
    if (self.tableViewController) {
        UITableViewController *tableViewController = self.tableViewController;
        [tableViewController.tableView registerNib:[UINib nibWithNibName:@"MITLogoReusableHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:MITRootLogoHeaderReuseIdentifier];
        tableViewController.tableView.delegate = self;
        tableViewController.tableView.dataSource = self;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([self.viewControllers count] == 0) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"drawer view controller must have at least 1 view controller added before being presented" userInfo:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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

- (void)setViewControllers:(NSArray *)viewControllers
{
    if (![_viewControllers isEqualToArray:viewControllers]) {
        UIViewController *selectedViewController = self.selectedViewController;
        NSUInteger selectedIndex = self.selectedIndex;

        _viewControllers = [viewControllers copy];

        if ([_viewControllers containsObject:selectedViewController]) {
            self.selectedViewController = selectedViewController;
        } else if (self.selectedIndex < [_viewControllers count]) {
            // Force a refresh of the current index since it may have changed
            self.selectedIndex = selectedIndex;
        } else {
            self.selectedIndex = 0;
        }
    }
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController
{
    if ([self.viewControllers containsObject:selectedViewController]) {
        _selectedViewController = selectedViewController;
        _selectedIndex = [self.viewControllers indexOfObject:selectedViewController];
        self.topViewController = _selectedViewController;
    } else {

    }

    [self resetTopViewAnimated:YES];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    NSRange indexRange = NSMakeRange(0, [self.viewControllers count]);
    if (NSLocationInRange(selectedIndex, indexRange)) {
        _selectedIndex = selectedIndex;
        _selectedViewController = [self.viewControllers objectAtIndex:selectedIndex];
        self.topViewController = _selectedViewController;
    } else {
        NSString *reason = [NSString stringWithFormat:@"index (%d) is beyond bounds (%d)",selectedIndex,[self.viewControllers count]];
        @throw [NSException exceptionWithName:NSRangeException reason:reason userInfo:nil];
    }

    [self resetTopViewAnimated:YES];
}

- (id<UIViewControllerTransitionCoordinator>)transitionCoordinator
{
    return nil;
}

#pragma mark Private
- (MITDrawerItem*)_drawerItemForViewControllerAtIndex:(NSUInteger)index
{
    UIViewController *viewController = self.viewControllers[index];

    if (!viewController.drawerItem) {
        return [[MITDrawerItem alloc] initWithTitle:viewController.title image:nil];
    } else {
        return viewController.drawerItem;
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
        } else {
            cell.imageView.image = drawerItem.image;
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

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        cell.contentView.backgroundColor = [UIColor mit_tintColor];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        cell.contentView.backgroundColor = [UIColor clearColor];
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
