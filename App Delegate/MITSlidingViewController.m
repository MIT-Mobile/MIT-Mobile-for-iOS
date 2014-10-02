#import "MITSlidingViewController.h"
#import "MITAdditions.h"
#import "MITModule.h"
#import "MITDrawerViewController.h"

static NSString* const MITRootLogoHeaderReuseIdentifier = @"RootLogoHeaderReuseIdentifier";

@interface MITSlidingViewController () <ECSlidingViewControllerDelegate, UINavigationControllerDelegate, MITDrawerViewControllerDelegate>
@property(nonatomic,readonly) MITDrawerViewController *drawerViewController;

@property(nonatomic,weak) id<UIViewControllerAnimatedTransitioning,ECSlidingViewControllerLayout> animationController;
@end

@implementation MITSlidingViewController
@dynamic drawerViewController;

- (instancetype)initWithViewControllers:(NSArray*)viewControllers;
{
    if (self) {
        _viewControllers = [viewControllers copy];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!([self.viewControllers count] > 0)) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"there must be at least one module added before being presented" userInfo:nil];
    }
    
    self.slidingViewController.delegate = self;
    self.drawerViewController.delegate = self;
    
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

- (ECSlidingViewController*)slidingViewController
{
    if (![self isSlidingViewControllerLoaded]) {
        [self loadSlidingViewController];
        NSAssert(_slidingViewController,@"failed to load slidingViewController");
    }
    
    return _slidingViewController;
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
            if (![viewController isKindOfClass:[MITModuleViewController class]]) {
                DDLogWarn(@"View Controller %@ is not a subclass of %@",viewController,NSStringFromClass([MITModuleViewController class]));
                return NO;
            }
            
            MITModuleViewController *moduleViewController = (MITModuleViewController*)viewController;
            
            if ([moduleViewController isCurrentUserInterfaceIdiomSupported]) {
                return YES;
            } else {
                return NO;
            }
        }]];
        
        NSMutableArray *newModuleItems = [[NSMutableArray alloc] init];
        [_viewControllers enumerateObjectsUsingBlock:^(MITModuleViewController *moduleViewController, NSUInteger idx, BOOL *stop) {
            MITModuleItem *moduleItem = moduleViewController.moduleItem;
            if (!moduleItem) {
                NSString *tag = [[moduleViewController.title lowercaseString] stringByReplacingOccurrencesOfString:@"_" withString:@""];
                moduleItem = [[MITModuleItem alloc] initWithTag:tag title:moduleViewController.title image:nil];
                moduleViewController.moduleItem = moduleItem;
            }
            
            [newModuleItems addObject:moduleItem];
        }];
        
        [self.drawerViewController setModuleItems:newModuleItems animated:animated];
        [self.drawerViewController setSelectedModuleItem:self.visibleViewController.moduleItem animated:animated];

        if (!self.isViewLoaded) {
            return;
        }
        
        if (oldViewControllers) {
            if (![oldViewControllers containsObject:self.visibleViewController]) {
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

- (void)setVisibleViewController:(UIViewController<MITModuleViewControllerProtocol> *)visibleViewController
{
    [self setVisibleViewController:visibleViewController animated:NO];
}

- (void)setVisibleViewController:(UIViewController<MITModuleViewControllerProtocol> *)newVisibleViewController animated:(BOOL)animated
{
    if (![self.viewControllers containsObject:newVisibleViewController]) {
        MITModuleItem *moduleItem = newVisibleViewController.moduleItem;
        NSString *reason = [NSString stringWithFormat:@"view controller does not have a module with tag '%@'",moduleItem.tag];
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
    }
    
    UIViewController *newTopViewController = newVisibleViewController;
    if (!newTopViewController) {
        newTopViewController = [[UIViewController alloc] init];
        
        UIView *view = [[UIView alloc] initWithFrame:self.slidingViewController.view.frame];
        view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        view.backgroundColor = [UIColor mit_backgroundColor];
        
        newTopViewController.view = view;
        _visibleViewController = nil;
    } else {
        _visibleViewController = newVisibleViewController;
    }
    
    self.drawerViewController.selectedModuleItem = _visibleViewController.moduleItem;
    
    if (self.slidingViewController.topViewController != newTopViewController) {
        [self.slidingViewController.topViewController.view removeGestureRecognizer:self.slidingViewController.panGesture];
        [self.slidingViewController setTopViewController:newTopViewController];
    }
    
    [newTopViewController.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    // If the top view is a UINavigationController, automatically add a button to toggle the state
    // of the sliding view controller. Otherwise, the user must either use the pan gesture or the view
    // controller must do something itself.
    if ([newVisibleViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController*)newTopViewController;
        navigationController.delegate = self;
    }
    
    [self.slidingViewController resetTopViewAnimated:YES];
}

- (void)setVisibleModuleWithTag:(NSString *)moduleTag
{
    UIViewController<MITModuleViewControllerProtocol> *module = [self _moduleViewControllerWithTag:moduleTag];
    [self setVisibleViewController:module];
}

- (BOOL)setVisibleModuleWithNotification:(NSDictionary*)notification
{
    NSAssert(NO, @"Not implemented yet");
    
    NSString *tag = notification[@"tag"];
    UIViewController<MITModuleViewControllerProtocol> *moduleViewController = [self _moduleViewControllerWithTag:tag];
    if (!moduleViewController) {
        DDLogInfo(@"module '%@' received a notification but failed to return a valid view controller", tag);
        return NO;
    }
    
    [self setVisibleViewController:moduleViewController animated:YES];
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
    UIViewController<MITModuleViewControllerProtocol> *viewController = [self _moduleViewControllerWithTag:tag];
    if (!viewController) {
        DDLogInfo(@"module '%@' received a notification but failed to return a valid view controller", tag);
        return NO;
    }
    
    [self setVisibleViewController:viewController animated:YES];
    return YES;
}

- (IBAction)toggleViewControllerPicker:(id)sender
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
    if (!self.visibleViewController) {
        self.visibleViewController = [self.viewControllers firstObject];
    }
}

- (UIViewController<MITModuleViewControllerProtocol>*)_moduleViewControllerWithTag:(NSString*)tag
{
    __block UIViewController<MITModuleViewControllerProtocol> *selectedModuleViewController = nil;
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController<MITModuleViewControllerProtocol> *moduleViewController, NSUInteger idx, BOOL *stop) {
        MITModuleItem *moduleItem = moduleViewController.moduleItem;
        
        if ([moduleItem.tag isEqualToString:tag]) {
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
        UIViewController *visibleViewController = self.visibleViewController;
        if (!visibleViewController) {
            visibleViewController = [[UIViewController alloc] init];
            
            UIView *emptyView = [[UIView alloc] initWithFrame:self.view.bounds];
            emptyView.backgroundColor = [UIColor mit_backgroundColor];
            visibleViewController.view = emptyView;
        }

        ECSlidingViewController *slidingViewController = nil;
        
        if (self.slidingViewControllerStoryboardId) {
            slidingViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.slidingViewControllerStoryboardId];
        } else {
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
    UIViewController<MITModuleViewControllerProtocol> *moduleViewController = [self _moduleViewControllerWithTag:moduleItem.tag];
    
    if (moduleViewController) {
        self.visibleViewController = moduleViewController;
    }
}
@end
