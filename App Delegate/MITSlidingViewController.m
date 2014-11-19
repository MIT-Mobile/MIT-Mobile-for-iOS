#import "MITSlidingViewController.h"
#import "MITModule.h"
#import "MITModuleItem.h"
#import "MITDrawerViewController.h"
#import "MITAdditions.h"
#import "MITSlidingAnimationController.h"

NSString * const MITSlidingViewControllerModulePushSegueIdentifier = @"MITSlidingViewControllerModulePushSegue";
NSString * const MITSlidingViewControllerUnderLeftSegueIdentifier = @"MITSlidingViewControllerUnderLeftSegue";
NSString * const MITSlidingViewControllerTopSegueIdentifier = @"MITSlidingViewControllerTopSegue";

static CGFloat const MITSlidingViewControllerDefaultAnchorRightPeekAmountPad = 270.;

// This number was picked in order to have an equal amount of whitespace on either
// side of the leftBarButtonIcon. 54pt results in having 14pt of whitespace on either side.
// This was tested on iOS 8 and iOS 7
// (bskinner - 2014.11.14)
static CGFloat const MITSlidingViewControllerDefaultAnchorRightPeekAmountPhone = 54.;


@interface MITSlidingViewController () <ECSlidingViewControllerDelegate,UINavigationControllerDelegate, MITDrawerViewControllerDelegate>
@property(nonatomic,weak) MITDrawerViewController *drawerViewController;
@property(nonatomic,strong) UIBarButtonItem *leftBarButtonItem;

@property(nonatomic,weak) MITSlidingAnimationController *animationController;

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
    
    [self performSegueWithIdentifier:MITSlidingViewControllerUnderLeftSegueIdentifier sender:self];
    [self performSegueWithIdentifier:MITSlidingViewControllerTopSegueIdentifier sender:self];
    
    self.delegate = self;
    
    self.topViewController.view.backgroundColor = [UIColor mit_backgroundColor];

    NSAssert(self.underLeftViewController, @"slidingViewController does not have a valid underLeftViewController");
    NSAssert([self.underLeftViewController isKindOfClass:[UINavigationController class]], @"underLeftViewController is a kind of %@, expected %@",NSStringFromClass([self.underLeftViewController class]),NSStringFromClass([UINavigationController class]));

    UINavigationController *drawerNavigationController = (UINavigationController*)self.underLeftViewController;
    MITDrawerViewController *drawerTableViewController = (MITDrawerViewController*)[drawerNavigationController.viewControllers firstObject];
    NSAssert([drawerTableViewController isKindOfClass:[MITDrawerViewController class]], @"underLeftViewController's root view is a kind of %@, expected %@",NSStringFromClass([drawerTableViewController class]), NSStringFromClass([MITDrawerViewController class]));
    
    drawerTableViewController.delegate = self;
    self.drawerViewController = drawerTableViewController;
    [self.topViewController.view addGestureRecognizer:self.panGesture];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!([self.viewControllers count] > 0)) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"there must be at least one module added before being presented" userInfo:nil];
    }

    switch ([UIDevice currentDevice].userInterfaceIdiom) {
        case UIUserInterfaceIdiomPhone: {
            self.anchorRightPeekAmount = MITSlidingViewControllerDefaultAnchorRightPeekAmountPhone;
        } break;

        case UIUserInterfaceIdiomPad: {
            self.anchorRightPeekAmount = MITSlidingViewControllerDefaultAnchorRightPeekAmountPad;
        } break;

        default: {
            // Leave it alone
        } break;
    }
    
    [self _showInitialModuleIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGestureTapping | ECSlidingViewControllerAnchoredGesturePanning;
    self.customAnchoredGestures = @[];
}

#pragma mark Overrides
- (void)anchorTopViewToRightAnimated:(BOOL)animated onComplete:(void (^)())complete {
    [super anchorTopViewToRightAnimated:animated onComplete:^{
        [self _updateScrollsToTop];
        
        if (complete) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                complete();
            }];
        }
    }];
}

- (void)resetTopViewAnimated:(BOOL)animated onComplete:(void(^)())complete {
    [super resetTopViewAnimated:animated onComplete:^{
        [self _updateScrollsToTop];
        
        if (complete) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                complete();
            }];
        }
    }];
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

    UIViewController *oldVisibleViewController = _visibleViewController;
    _visibleViewController = newVisibleViewController;
    
    self.drawerViewController.selectedModuleItem = _visibleViewController.moduleItem;
    
    UIStoryboardSegue *modulePushSegue = [UIStoryboardSegue segueWithIdentifier:MITSlidingViewControllerModulePushSegueIdentifier source:self destination:newVisibleViewController performHandler:^{
        UIViewController *fromViewController = self;
        
        NSAssert([fromViewController isKindOfClass:[ECSlidingViewController class]], @"sourceViewController is kind of %@, expected kind of %@",NSStringFromClass([fromViewController class]), NSStringFromClass([ECSlidingViewController class]));
        ECSlidingViewController *slidingViewController = (ECSlidingViewController*)fromViewController;
        
        // If the top view is a UINavigationController, automatically add a button to toggle the state
        // of the sliding view controller. Otherwise, the user must either use the pan gesture or the view
        // controller must do something itself.
        if ([newVisibleViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController*)newVisibleViewController;
            UIViewController *rootViewController = [navigationController.viewControllers firstObject];
            
            if (!rootViewController.navigationItem.leftBarButtonItem) {
                rootViewController.navigationItem.leftBarButtonItem = self.leftBarButtonItem;
            }
        }
        
        UIViewController *topViewController = slidingViewController.topViewController;
        newVisibleViewController.view.frame = topViewController.view.bounds;
        
        [oldVisibleViewController willMoveToParentViewController:nil];
        [oldVisibleViewController.view removeFromSuperview];
        [oldVisibleViewController removeFromParentViewController];
        
        [topViewController addChildViewController:newVisibleViewController];
        [topViewController.view addSubview:newVisibleViewController.view];
        [newVisibleViewController didMoveToParentViewController:topViewController];
        
        if (slidingViewController.currentTopViewPosition != ECSlidingViewControllerTopViewPositionCentered) {
            [slidingViewController resetTopViewAnimated:YES];
        }
    }];
    
    [self prepareForSegue:modulePushSegue sender:self];
    [modulePushSegue perform];
}

- (void)setVisibleViewControllerWithModuleName:(NSString *)name
{
    UIViewController *moduleViewController = [self _moduleViewControllerWithName:name];
    [self setVisibleViewController:moduleViewController];
}


- (void)showModuleSelector:(BOOL)animated completion:(void(^)(void))block
{
    if (self.currentTopViewPosition == ECSlidingViewControllerTopViewPositionCentered) {
        [self anchorTopViewToRightAnimated:animated onComplete:block];
    }
}

- (void)hideModuleSelector:(BOOL)animated completion:(void(^)(void))block
{
    if (self.currentTopViewPosition != ECSlidingViewControllerTopViewPositionCentered) {
        [self resetTopViewAnimated:animated onComplete:block];
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

- (void)_updateScrollsToTop
{
    BOOL topViewNeedsScrollsToTop = NO;
    if (self.currentTopViewPosition == ECSlidingViewControllerTopViewPositionCentered) {
        topViewNeedsScrollsToTop = YES;
    }
    
    BOOL stop = NO;
    NSMutableOrderedSet *topSubviews = [NSMutableOrderedSet orderedSetWithObject:self.topViewController.view];
    while ([topSubviews count] || !stop) {
        UIView *view = [topSubviews firstObject];
        [topSubviews removeObject:view];
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView*)view;
            scrollView.scrollsToTop = topViewNeedsScrollsToTop;
            stop = YES;
        } else if ([view.subviews count]) {
            [topSubviews addObjectsFromArray:view.subviews];
        } else {
            stop = YES;
        }
    }
    
    stop = NO;
    NSMutableArray *underLeftSubviews = [NSMutableArray arrayWithObject:self.underLeftViewController.view];
    while ([underLeftSubviews count] || !stop) {
        UIView *view = [underLeftSubviews firstObject];
        [underLeftSubviews removeObject:view];
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView*)view;
            scrollView.scrollsToTop = !topViewNeedsScrollsToTop;
            stop = YES;
        } else if ([view.subviews count]) {
            [underLeftSubviews addObjectsFromArray:view.subviews];
        } else {
            stop = YES;
        }
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

- (id<ECSlidingViewControllerLayout>)slidingViewController:(ECSlidingViewController *)slidingViewController
                        layoutControllerForTopViewPosition:(ECSlidingViewControllerTopViewPosition)topViewPosition
{
    return self.animationController;
}

- (id<UIViewControllerAnimatedTransitioning>)slidingViewController:(ECSlidingViewController *)slidingViewController
                                   animationControllerForOperation:(ECSlidingViewControllerOperation)operation
                                                 topViewController:(UIViewController *)topViewController
{
    MITSlidingAnimationController *slidingAnimationController = [[MITSlidingAnimationController alloc] initWithSlidingViewController:slidingViewController operation:operation];
    self.animationController = slidingAnimationController;

    return self.animationController;
}

@end
