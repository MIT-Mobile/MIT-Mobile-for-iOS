#import "MITRootViewController.h"
#import "ECSlidingViewController.h"
#import "MITModule.h"
#import "MITLauncher.h"
#import "MITLauncherGridViewController.h"
#import "MITLauncherListViewController.h"
#import "MITNavigationController.h"

#import "MITAdditions.h"

@interface MITRootViewController () <MITLauncherDataSource,MITLauncherDelegate>
@property (nonatomic,strong) NSArray *availableModules;
@property (nonatomic,weak) MITModule *lastSelectedModule;

@property (nonatomic,weak) ECSlidingViewController *rootDrawerViewController;
@property (nonatomic,weak) UITableViewController *moduleListViewController;
@end

@implementation MITRootViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


#pragma mark Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.autoresizesSubviews = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.lastSelectedModule) {
        [self _presentModule:[self.modules firstObject] animated:animated];
    }
}

#pragma mark Drawer interface specific method
- (void)setLeftDrawerVisible:(BOOL)visible animated:(BOOL)animated
{
    if (self.rootDrawerViewController) {
        [self.rootDrawerViewController anchorTopViewToRightAnimated:animated onComplete:nil];
    }
}

#pragma mark Managing the available modules
- (void)setModules:(NSArray *)modules
{
    NSAssert([modules count] > 0, @"there must be at least 1 module present");

    if (![_modules isEqualToArray:modules]) {
        _modules = [modules copy];
        [self didChangeAvailableModules];
    }
}

- (void)didChangeAvailableModules
{
    if (self.rootNavigationViewController) {
        [self.moduleSpringboardViewController.collectionView reloadData];
    } else if (self.rootDrawerViewController) {
        [self.moduleListViewController.tableView reloadData];
    }
}

- (void)_presentModule:(MITModule*)module animated:(BOOL)animated
{
    if (style == MITInterfaceStyleDrawer) {
        UIViewController *moduleViewController = [module homeViewController];

        NSSet *navigationViewControllerClasses = [NSSet setWithArray:@[[UINavigationController class],[UISplitViewController class],[UITabBarController class]]];
        __block BOOL usesModuleHomeViewControllerDirectly = NO;
        [navigationViewControllerClasses enumerateObjectsUsingBlock:^(Class klass, BOOL *stop) {
            if ([moduleViewController isKindOfClass:klass]) {
                usesModuleHomeViewControllerDirectly = YES;
                (*stop) = YES;
            }
        }];

        if (usesModuleHomeViewControllerDirectly) {

        } else {

        }
    } else if (style == MITInterfaceStyleSpringboard) {
        UIViewController *moduleHomeController = module.homeViewController;
        if ([self.rootNavigationViewController.viewControllers containsObject:moduleHomeController]) {
            [self.rootNavigationViewController popToViewController:moduleHomeController animated:animated];
        } else {
            [self.rootNavigationViewController popToViewController:self.moduleSpringboardViewController animated:NO];
            [self.rootNavigationViewController pushViewController:moduleHomeController animated:animated];
        }
    } else {
        NSString *message = [NSString stringWithFormat:@"unsupported interface style %d",style];
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:message userInfo:nil];
    }

    self.lastSelectedModule = module;
}

- (BOOL)showModuleWithTag:(NSString*)moduleTag
{
    return [self showModuleWithTag:moduleTag animated:NO];
}

- (BOOL)showModuleWithTag:(NSString*)moduleTag animated:(BOOL)animated
{
    NSParameterAssert(moduleTag);

    __block MITModule *newActiveModule = nil;
    [self.modules enumerateObjectsUsingBlock:^(MITModule *module, NSUInteger idx, BOOL *stop) {
        if ([module.tag isEqualToString:moduleTag]) {
            newActiveModule = module;
            (*stop) = YES;
        }
    }];

    if (newActiveModule) {
        [self _presentModule:newActiveModule forInterfaceStyle:self.interfaceStyle animated:animated];
        return YES;
    } else {
        return NO;
    }
}

- (void)_presentViewControllerForDrawerInterface:(BOOL)animated completion:(void (^)(BOOL finished))block
{
    if (self.rootDrawerViewController) {
        if (self.interfaceStyle == MITInterfaceStyleDrawer) {
            // We are already in the correct interface and the drawer already exists.
            // There's nothing left to do so just bail at this point.
            // Reasoning: Both root-level view controllers are weak references. If a reference
            //  exists, it is a child view controller and should be considered 'active'. If both
            //  the root view controllers exist, we have a serious problem and anything we do
            //  at this point will only make it worse.
            return;
        } else if (self.interfaceStyle == MITInterfaceStyleSpringboard) {
            // Big trouble. Somehow we are in the springboard interface style but a drawer
            // view controller exists. There is no safe way to recover from this since we don't know
            // what sort of state we are dealing with. Fire off an exception to let someone know that
            // there was a serious screw up.
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"the springboard interface style is active but a drawer view controller already exists" userInfo:nil];
        }
    } else {


        [self _transitionFromViewController:self.rootNavigationViewController toViewController:self.rootDrawerViewController animated:YES completion:block];
    }
}

- (void)willTransitionToInterfaceStyle:(MITInterfaceStyle)newStyle animated:(BOOL)animated
{
    // Default implementation does nothing
}

- (void)didTransitionFromInterfaceStyle:(MITInterfaceStyle)oldStyle animated:(BOOL)animated
{
    // Default implementation does nothing
}


#pragma mark Delegation
#pragma mark MITLauncherDataSource
- (NSUInteger)numberOfItemsInLauncher:(MITLauncherGridViewController *)launcher
{
    return [self.modules count];
}

- (MITModule*)launcher:(MITLauncherGridViewController *)launcher moduleAtIndexPath:(NSIndexPath *)index
{
    return self.modules[index.row];
}

#pragma mark MITLauncherDelegate
- (void)launcher:(MITLauncherGridViewController *)launcher didSelectModuleAtIndexPath:(NSIndexPath *)indexPath
{
    [self _presentModule:self.modules[indexPath.row] forInterfaceStyle:self.interfaceStyle animated:YES];
}

@end
