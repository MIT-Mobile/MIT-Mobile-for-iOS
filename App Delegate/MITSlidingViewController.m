#import "MITSlidingViewController.h"
#import "MITModule.h"
#import "MITModuleItem.h"
#import "MITDrawerViewController.h"
#import "MITAdditions.h"

static NSString* const MITDrawerNavigationControllerStoryboardId = @"DrawerNavigationController";
static NSString* const MITDrawerTableViewControllerStoryboardId = @"DrawerTableViewController";

@interface MITSlidingViewController () <ECSlidingViewControllerDelegate,UINavigationControllerDelegate, MITDrawerViewControllerDelegate>
@property(nonatomic,weak) MITDrawerViewController *drawerViewController;
@property(nonatomic,strong) UIBarButtonItem *leftBarButtonItem;

- (NSArray*)moduleItems;
@end

@implementation MITSlidingViewController
- (instancetype)initWithViewControllers:(NSArray*)viewControllers;
{
    if (self) {
        _viewControllers = [viewControllers copy];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSAssert(self.slidingViewControllerStoryboardId, @"slidingViewControllerStoryboardId may not be nil.");

    ECSlidingViewController *slidingViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.slidingViewControllerStoryboardId];

    NSAssert([slidingViewController isKindOfClass:[ECSlidingViewController class]],@"object with storyboard ID %@ is a kind of %@, expected %@", self.slidingViewControllerStoryboardId,NSStringFromClass([slidingViewController class]),NSStringFromClass([ECSlidingViewController class]));
    NSAssert(slidingViewController.underLeftViewController, @"slidingViewController does not have a valid underLeftViewController");
    NSAssert([slidingViewController.underLeftViewController isKindOfClass:[UINavigationController class]], @"underLeftViewController is a kind of %@, expected %@",NSStringFromClass([slidingViewController.underLeftViewController class]),NSStringFromClass([UINavigationController class]));

    [self addChildViewController:slidingViewController];
    slidingViewController.view.frame = self.view.bounds;
    [self.view addSubview:slidingViewController.view];
    [slidingViewController didMoveToParentViewController:self];

    UINavigationController *drawerNavigationController = (UINavigationController*)slidingViewController.underLeftViewController;
    MITDrawerViewController *drawerTableViewController = (MITDrawerViewController*)[drawerNavigationController.viewControllers firstObject];
    NSAssert([drawerTableViewController isKindOfClass:[MITDrawerViewController class]], @"underLeftViewController's root view is a kind of %@, expected %@",NSStringFromClass([drawerTableViewController class]), NSStringFromClass([MITDrawerViewController class]));

    self.slidingViewController = slidingViewController;
    self.slidingViewController.delegate = self;

    self.drawerViewController = drawerTableViewController;
    self.drawerViewController.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!([self.viewControllers count] > 0)) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"there must be at least one module added before being presented" userInfo:nil];
    }

    [self _showInitialModuleIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.slidingViewController.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGestureTapping | ECSlidingViewControllerAnchoredGesturePanning;
    self.slidingViewController.customAnchoredGestures = @[];
}

#pragma mark Properties
- (UIBarButtonItem*)leftBarButtonItem
{
    if (!_leftBarButtonItem) {
        UIImage *image = [UIImage imageNamed:MITImageBarButtonMenu];
        _leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(_showModuleSelector:)];
    }
    
    return _leftBarButtonItem;
}

- (ECSlidingViewController*)slidingViewController
{
    if (![self isSlidingViewControllerLoaded]) {
        [self loadSlidingViewController];
        NSAssert(_slidingViewController,@"failed to load slidingViewController");
    }
    
    return _slidingViewController;
}

- (NSArray*)moduleItems
{
    NSMutableArray *moduleItems = [[NSMutableArray alloc] init];
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        MITModuleItem *moduleItem = viewController.moduleItem;
        if (moduleItem) {
            [moduleItems addObject:moduleItem];
        }
    }];

    return moduleItems;
}

- (void)setViewControllers:(NSArray *)viewControllers
{
    [self setViewControllers:viewControllers animated:NO];
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated
{
    if (![_viewControllers isEqualToArray:viewControllers]) {
        NSArray *oldViewControllers = _viewControllers;

        _viewControllers = [viewControllers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIViewController *viewController, NSDictionary *bindings) {
            MITModuleItem *moduleItem = viewController.moduleItem;
            if (moduleItem) {
                return YES;
            } else {
                NSLog(@"%@ does not have a valid module item",viewController);
                return NO;
            }
        }]];
        
        [self.drawerViewController setModuleItems:[self moduleItems] animated:animated];
        [self.drawerViewController setSelectedModuleItem:self.visibleViewController.moduleItem animated:animated];

        if (!self.isViewLoaded) {
            return;
        }
        
        if (self.visibleViewController && oldViewControllers) {
            if ([oldViewControllers containsObject:self.visibleViewController]) {
                NSUInteger selectedIndex = [oldViewControllers indexOfObject:self.visibleViewController];
                NSRange indexRange = NSMakeRange(0, [_viewControllers count]);
                
                if (NSLocationInRange(selectedIndex, indexRange)) {
                    self.visibleViewController = _viewControllers[selectedIndex];
                } else {
                    self.visibleViewController = [_viewControllers firstObject];
                }
            }
        } else {
            self.visibleViewController = [_viewControllers firstObject];
        }
    }
}

- (void)setVisibleViewController:(UIViewController*)visibleViewController
{
    [self setVisibleViewController:visibleViewController animated:NO];
}

- (void)setVisibleViewController:(UIViewController*)newVisibleViewController animated:(BOOL)animated
{
    NSParameterAssert(newVisibleViewController);

    if (![self.viewControllers containsObject:newVisibleViewController]) {
        MITModuleItem *moduleItem = newVisibleViewController.moduleItem;
        NSString *reason = [NSString stringWithFormat:@"view controller does not have a module with tag '%@'",moduleItem.name];
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
    }

    _visibleViewController = newVisibleViewController;
    
    self.drawerViewController.selectedModuleItem = _visibleViewController.moduleItem;
    
    if (self.slidingViewController.topViewController != newVisibleViewController) {
        [self.slidingViewController.topViewController.view removeGestureRecognizer:self.slidingViewController.panGesture];
        self.slidingViewController.topViewController = newVisibleViewController;
        newVisibleViewController.view.backgroundColor = [UIColor mit_backgroundColor];
    }

    if (![self.slidingViewController.view.gestureRecognizers containsObject:self.slidingViewController.panGesture]) {
        [newVisibleViewController.view addGestureRecognizer:self.slidingViewController.panGesture];
    }
    
    // If the top view is a UINavigationController, automatically add a button to toggle the state
    // of the sliding view controller. Otherwise, the user must either use the pan gesture or the view
    // controller must do something itself.
    if ([newVisibleViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController*)newVisibleViewController;
        UIViewController *rootViewController = [navigationController.viewControllers firstObject];
        rootViewController.navigationItem.leftBarButtonItem = self.leftBarButtonItem;
    }

    if (self.slidingViewController.currentTopViewPosition != ECSlidingViewControllerTopViewPositionCentered) {
        [self.slidingViewController resetTopViewAnimated:YES];
    }
}

- (void)setVisibleViewControllerWithModuleName:(NSString *)name
{
    UIViewController *moduleViewController = [self _moduleViewControllerWithName:name];
    [self setVisibleViewController:moduleViewController];
}


- (void)showModuleSelector:(BOOL)animated completion:(void(^)(void))block
{
    if (self.slidingViewController.currentTopViewPosition == ECSlidingViewControllerTopViewPositionCentered) {
        [self.slidingViewController anchorTopViewToRightAnimated:animated onComplete:block];
    }
}

- (void)hideModuleSelector:(BOOL)animated completion:(void(^)(void))block
{
    if (self.slidingViewController.currentTopViewPosition != ECSlidingViewControllerTopViewPositionCentered) {
        [self.slidingViewController resetTopViewAnimated:animated onComplete:block];
    }
}

#pragma mark Private
- (IBAction)_showModuleSelector:(id)sender
{
    [self showModuleSelector:YES completion:nil];
}

- (void)_showInitialModuleIfNeeded
{
    if (!self.visibleViewController) {
        self.drawerViewController.moduleItems = [self moduleItems];
        self.visibleViewController = [self.viewControllers firstObject];
    }
}

- (UIViewController*)_moduleViewControllerWithName:(NSString*)name
{
    __block UIViewController *selectedModuleViewController = nil;
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *moduleViewController, NSUInteger idx, BOOL *stop) {
        MITModuleItem *moduleItem = moduleViewController.moduleItem;
        
        if ([moduleItem.name isEqualToString:name]) {
            selectedModuleViewController = moduleViewController;
            (*stop) = YES;
        }
    }];

    return selectedModuleViewController;
}

- (BOOL)isSlidingViewControllerLoaded
{
    return (_slidingViewController != nil);
}

- (void)loadSlidingViewController
{
    if (![self isSlidingViewControllerLoaded]) {
        ECSlidingViewController *slidingViewController = nil;
        
        if (self.slidingViewControllerStoryboardId) {
            slidingViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.slidingViewControllerStoryboardId];
        } else {
            UIViewController *visibleViewController = [[UIViewController alloc] init];

            UIView *emptyView = [[UIView alloc] initWithFrame:self.view.bounds];
            emptyView.backgroundColor = [UIColor whiteColor];
            emptyView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
            visibleViewController.view = emptyView;

            slidingViewController = [[ECSlidingViewController alloc] initWithTopViewController:visibleViewController];
        }

        [self addChildViewController:slidingViewController];

        slidingViewController.view.frame = self.view.bounds;
        [self.view addSubview:slidingViewController.view];
        [slidingViewController didMoveToParentViewController:self];
        
        _slidingViewController = slidingViewController;
    }
}

#pragma mark Delegation
- (void)drawerViewController:(MITDrawerViewController *)drawerViewController didSelectModuleItem:(MITModuleItem *)moduleItem
{
    UIViewController *moduleViewController = [self _moduleViewControllerWithName:moduleItem.name];
    
    if (moduleViewController) {
        // Call the application delegate directly to change the module so we follow the same
        // event handling as everything else.
        // May need to rework this once we see how it functions.
        // (bskinner - 2014.11.07
        [[MIT_MobileAppDelegate applicationDelegate] showModuleWithTag:moduleItem.name animated:YES];
    }
}

@end
