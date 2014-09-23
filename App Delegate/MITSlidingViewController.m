#import "MITSlidingViewController.h"
#import "MITAdditions.h"
#import "MITModule.h"
#import "MITDrawerViewController.h"

static NSString* const MITRootLogoHeaderReuseIdentifier = @"RootLogoHeaderReuseIdentifier";

@interface MITSlidingViewController () <ECSlidingViewControllerDelegate, UINavigationControllerDelegate>
@property(nonatomic,readonly) MITDrawerViewController *drawerViewController;
@property(nonatomic,weak) id<UIViewControllerAnimatedTransitioning,ECSlidingViewControllerLayout> animationController;
@end

@implementation MITSlidingViewController
@dynamic drawerViewController;

- (instancetype)initWithModules:(NSArray *)modules
{
    if (self) {
        _modules = [modules copy];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!([self.modules count] > 0)) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"there must be at least one module added before being presented" userInfo:nil];
    }

    if (![self isSlidingViewControllerLoaded]) {
        [self loadSlidingViewController:animated];
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
- (MITDrawerViewController*)drawerViewController
{
    if ([self.slidingViewController.underLeftViewController isKindOfClass:[MITDrawerViewController class]]) {
        return (MITDrawerViewController*)self.slidingViewController.underLeftViewController;
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
        NSArray *previousModules = _modules;
        _modules = [modules filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(MITModule *module, NSDictionary *bindings) {
            UIUserInterfaceIdiom interfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
            if ([module supportsUserInterfaceIdiom:interfaceIdiom]) {
                return YES;
            } else {
                return NO;
            }
        }]];

        if (![previousModules containsObject:self.visibleModule]) {
            NSUInteger selectedIndex = [previousModules indexOfObject:self.visibleModule];
            NSRange indexRange = NSMakeRange(0, [_modules count]);

            if (NSLocationInRange(selectedIndex, indexRange)) {
                self.visibleModule = _modules[selectedIndex];
            } else {
                self.visibleModule = [_modules firstObject];
            }
        }

        self.drawerViewController.modules = _modules;
    }
}

- (void)setVisibleModule:(MITModule*)module
{
    if (![self.modules containsObject:module]) {
        NSString *reason = [NSString stringWithFormat:@"view controller does not have a module with tag '%@'",module.tag];
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
    }

    [self setVisibleModule:module withViewController:module.homeViewController];
}

- (void)setVisibleModuleWithTag:(NSString *)moduleTag
{
    MITModule *module = [self _moduleWithTag:moduleTag];
    [self setVisibleModule:module];
}

- (BOOL)setVisibleModuleWithNotification:(MITNotification *)notification
{
    NSAssert(NO, @"Not implemented yet");
    
    MITModule *module = [self _moduleWithTag:notification.tag];
    if (!module) {
        DDLogWarn(@"failed to find module with tag '%@'", notification.tag);
        return NO;
    }

    UIViewController *viewController = nil;
    if (!viewController) {
        DDLogInfo(@"module '%@' received a notification but failed to return a valid view controller", module.tag);
        return NO;
    }

    [self setVisibleModule:module withViewController:viewController];
    return YES;
}

- (BOOL)setVisibleModuleWithURL:(NSURL *)url
{
    NSAssert(NO, @"Not implemented yet");
    
    if (![url.scheme isEqualToString:MITInternalURLScheme]) {
        DDLogWarn(@"unable to open URL with scheme '%@'",url.scheme);
        return NO;
    }
    
    NSString *tag = url.host;
    MITModule *module = [self _moduleWithTag:tag];
    if (!module) {
        DDLogWarn(@"failed to find module with tag '%@'",tag);
        return NO;
    }
    
    UIViewController *viewController = nil;
    if (!viewController) {
        DDLogInfo(@"module '%@' received a notification but failed to return a valid view controller", module.tag);
        return NO;
    }
    
    [self setVisibleModule:module withViewController:viewController];
    return YES;
}

- (void)setVisibleModule:(MITModule*)module withViewController:(UIViewController*)newTopViewController
{
    if (!newTopViewController) {
        newTopViewController = [[UIViewController alloc] init];

        UIView *view = [[UIView alloc] initWithFrame:self.view.frame];
        view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        view.backgroundColor = [UIColor mit_backgroundColor];

        newTopViewController.view = view;
    }

    _visibleModule = module;
    self.drawerViewController.selectedModule = module;
    
    if (self.slidingViewController.topViewController != newTopViewController) {
        [self.slidingViewController.topViewController.view removeGestureRecognizer:self.slidingViewController.panGesture];
        [self.slidingViewController setTopViewController:newTopViewController];
    }

    [newTopViewController.view addGestureRecognizer:self.slidingViewController.panGesture];

    // If the top view is a UINavigationController, automatically add a button to toggle the state
    // of the sliding view controller. Otherwise, the user must either use the pan gesture or the view
    // controller must do something itself.
    if ([newTopViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController*)newTopViewController;
        navigationController.delegate = self;
    }

    [self.slidingViewController resetTopViewAnimated:YES];
}

- (IBAction)toggleAnchorRight:(id)sender
{
    if (self.slidingViewController.currentTopViewPosition == ECSlidingViewControllerTopViewPositionCentered) {
        [self.slidingViewController anchorTopViewToRightAnimated:YES];
    } else {
        [self.slidingViewController resetTopViewAnimated:YES];
    }
}

#pragma mark Private
- (void)_showInitialModuleIfNeeded
{
    if (!self.visibleModule) {
        self.visibleModule = [self.modules firstObject];
    }
}

- (MITModule*)_moduleWithTag:(NSString*)tag
{
    __block MITModule *selectedModule = nil;
    [self.modules enumerateObjectsUsingBlock:^(MITModule *module, NSUInteger idx, BOOL *stop) {
        if ([module.tag isEqualToString:tag]) {
            selectedModule = module;
            (*stop) = YES;
        }
    }];

    return selectedModule;
}

- (BOOL)isSlidingViewControllerLoaded
{
    return (_slidingViewController != nil);
}

- (void)loadSlidingViewController:(BOOL)animated
{
    if (![self isSlidingViewControllerLoaded]) {
        MITModule *topModule = self.visibleModule;
        if (!_visibleModule) {
            topModule = [self.modules firstObject];
        }

        ECSlidingViewController *slidingViewController = [[ECSlidingViewController alloc] initWithTopViewController:topModule.homeViewController];

        [self addChildViewController:slidingViewController];

        slidingViewController.view.frame = self.view.bounds;
        [self.view addSubview:slidingViewController.view];

        [UIView animateWithDuration:0.33
                         animations:^{

                         } completion:^(BOOL finished) {
                             [slidingViewController didMoveToParentViewController:self];
                         }];
    }
}

#pragma mark Delegation
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([navigationController.viewControllers firstObject] == viewController) {
        UIImage *image = [UIImage imageNamed:@"global/menu"];
        UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStyleDone target:self action:@selector(toggleAnchorRight:)];

        [viewController.navigationItem setLeftBarButtonItem:leftBarButtonItem animated:animated];
    }
}
@end
