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

// Used by the MITInterfaceStyleDrawer interface style.
// The ECSlidingViewController is the root view controller and the launcher list view controller
// is in the left drawer.
@property (nonatomic,weak) ECSlidingViewController *rootDrawerViewController;
@property (nonatomic,weak) MITLauncherListViewController *moduleListViewController;

// Used by the MITInterfaceStyleSpringboard interface style
@property (nonatomic,weak) UINavigationController *rootNavigationViewController;
@property (nonatomic,weak) MITLauncherGridViewController *moduleSpringboardViewController;
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
    [self transitionToInterfaceStyle:self.interfaceStyle animated:NO];
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
    // Find a better way to do this, we should not care how these are displayed
    [self.moduleListViewController.tableView reloadData];
    [self.moduleSpringboardViewController.collectionView reloadData];

    if (!(self.activeModule && [_modules containsObject:self.activeModule])) {
        self.activeModule = [_modules firstObject];
    }
}

- (void)setActiveModule:(MITModule *)activeModule
{
    if (![_activeModule isEqual:activeModule]) {
        MITModule *oldActiveModule = _activeModule;
        [self willShowModule:activeModule];

        [self didHideModule:oldActiveModule];
    }
}

- (BOOL)showModuleWithTag:(NSString*)moduleTag
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
        self.activeModule = newActiveModule;
        return YES;
    } else {
        return NO;
    }
}

#pragma mark Dynamic Setters
- (ECSlidingViewController*)rootDrawerViewController
{
    ECSlidingViewController *rootDrawerViewController = _rootDrawerViewController;
    if (!rootDrawerViewController) {
        // Using a dummy view controller to keep the sliding view controller happy
        UIViewController *dummyViewController = [[UIViewController alloc] init];
        dummyViewController.view.backgroundColor = [UIColor mit_backgroundColor];
    
        
        rootDrawerViewController = [[ECSlidingViewController alloc] initWithTopViewController:dummyViewController];
        
        MITLauncherListViewController *launcherViewController = [[MITLauncherListViewController alloc] init];
        launcherViewController.dataSource = self;
        launcherViewController.delegate = self;
        launcherViewController.edgesForExtendedLayout = (UIRectEdgeLeft | UIRectEdgeRight | UIRectEdgeBottom);
        self.moduleListViewController = launcherViewController;
        self.moduleSpringboardViewController = nil;
        
        rootDrawerViewController.underLeftViewController = launcherViewController;
        rootDrawerViewController.anchorRightRevealAmount = 280.;
        
        _rootDrawerViewController = rootDrawerViewController;
    }
    
    return rootDrawerViewController;
}

#pragma mark Changing the interface style
- (void)transitionToInterfaceStyle:(MITInterfaceStyle)style animated:(BOOL)animated
{
    BOOL needsInitialTransition = !(self.rootDrawerViewController || self.rootNavigationViewController);

    if (needsInitialTransition || (self.interfaceStyle != style)) {
        MITInterfaceStyle oldStyle = self.interfaceStyle;
        [self willTransitionToInterfaceStyle:style animated:animated];

        _interfaceStyle = style;
        if (style == MITInterfaceStyleSpringboard) {
            [self _presentViewControllerForSpringboardInterface:animated completion:nil];
        } else if (style == MITInterfaceStyleDrawer) {
            [self _presentViewControllerForSpringboardInterface:animated completion:nil];
        } else {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"unable to transition to new style, requested interface style is unknown" userInfo:nil];
        }
        
        [self didTransitionFromInterfaceStyle:oldStyle animated:animated];
    }
}

- (void)_transitionFromViewController:(UIViewController*)fromViewController toViewController:(UIViewController*)toViewController animated:(BOOL)animated completion:(void (^)(BOOL finished))block
{
    NSParameterAssert(toViewController);
    
    toViewController.view.translatesAutoresizingMaskIntoConstraints = YES;
    toViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    toViewController.view.frame = self.view.bounds;
    [self addChildViewController:toViewController];
    
    NSTimeInterval duration = (animated ? 0.25 : 0.);
    if (fromViewController) {
        // An existing drawer controller already exists, we'll need to transition between the two
        [fromViewController willMoveToParentViewController:nil];
        [self transitionFromViewController:fromViewController
                          toViewController:toViewController
                                  duration:duration
                                   options:(UIViewAnimationOptionBeginFromCurrentState |
                                            UIViewAnimationOptionTransitionCrossDissolve)
                                animations:^{
                                    // Nothing here at the moment
                                } completion:^(BOOL finished) {
                                    [fromViewController removeFromParentViewController];
                                    [toViewController didMoveToParentViewController:self];
                                    
                                    if (block) {
                                        block(finished);
                                    }
                                }];
    } else {
        // Otherwise, this is the first view controller being added, so play nice
        [self.view addSubview:toViewController.view];
        toViewController.view.alpha = 0.;
        [UIView animateWithDuration:duration
                         animations:^{
                             // Just face the view in at this point
                             toViewController.view.alpha = 1.;
                         } completion:^(BOOL finished) {
                             [toViewController didMoveToParentViewController:self];
                             if (block) {
                                 block(finished);
                             }
                         }];
    }
}

- (void)_presentViewControllerForSpringboardInterface:(BOOL)animated completion:(void (^)(BOOL finished))block
{
    MITLauncherGridViewController *springboardViewController = [[MITLauncherGridViewController alloc] init];
    springboardViewController.dataSource = self;
    springboardViewController.delegate = self;

    UIImage *logoView = [UIImage imageNamed:@"global/navbar_mit_logo_dark"];
    springboardViewController.navigationItem.titleView = [[UIImageView alloc] initWithImage:logoView];
    springboardViewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:nil action:nil];

    UINavigationController *navigationController = [[MITNavigationController alloc] initWithRootViewController:springboardViewController];
    navigationController.navigationBarHidden = NO;
    navigationController.toolbarHidden = YES;

    navigationController.navigationBar.barStyle = UIBarStyleDefault;
    navigationController.navigationBar.translucent = YES;

    self.rootNavigationViewController = navigationController;
    self.moduleSpringboardViewController = springboardViewController;

    [self _transitionFromViewController:self.rootDrawerViewController toViewController:self.rootNavigationViewController animated:YES completion:block];
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
        // Using a dummy view controller to keep the sliding view controller happy (it needs any view
        //  view controller when allocated). This will be replaced once we start activating modules
        UIViewController *dummyViewController = [[UIViewController alloc] init];
        dummyViewController.view.backgroundColor = [UIColor mit_backgroundColor];
        ECSlidingViewController *drawerViewController = [[ECSlidingViewController alloc] initWithTopViewController:dummyViewController];

        MITLauncherListViewController *launcherViewController = [[MITLauncherListViewController alloc] init];
        launcherViewController.dataSource = self;
        launcherViewController.delegate = self;
        launcherViewController.edgesForExtendedLayout = (UIRectEdgeLeft | UIRectEdgeRight | UIRectEdgeBottom);

        self.moduleListViewController = launcherViewController;

        drawerViewController.underLeftViewController = launcherViewController;
        drawerViewController.anchorRightRevealAmount = 280.;

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
    self.activeModule = self.modules[indexPath.row];
}

@end
