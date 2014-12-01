#import "MITSlidingViewController.h"
#import "MITModule.h"
#import "MITModuleItem.h"
#import "MITDrawerViewController.h"
#import "MITAdditions.h"
#import "MITSlidingAnimationController.h"

#import "MIT_MobileAppDelegate.h"
#import "MITConstants.h"

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
@dynamic leftBarButtonItem;
@dynamic drawerViewController;

- (instancetype)initWithViewControllers:(NSArray*)viewControllers;
{
    if (self) {
        _viewControllers = [viewControllers copy];
    }

    return self;
}

- (void)viewDidLoad {
    // Performing the segues before calling super's viewDidLoad because, otherwise, ECSlidingViewController
    // will complain that the topViewController has not been loaded yet.
    [self performSegueWithIdentifier:MITSlidingViewControllerUnderLeftSegueIdentifier sender:self];
    [self performSegueWithIdentifier:MITSlidingViewControllerTopSegueIdentifier sender:self];

    [super viewDidLoad];

    self.delegate = self;
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


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];

    if ([segue.identifier isEqualToString:MITSlidingViewControllerTopSegueIdentifier]) {
        UIViewController *topViewController = segue.destinationViewController;

        [topViewController.view addGestureRecognizer:self.panGesture];

        topViewController.view.layer.shadowOpacity = 1.0;
        topViewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
    } else if ([segue.identifier isEqualToString:MITSlidingViewControllerUnderLeftSegueIdentifier]) {
        UIViewController *underLeftViewController = segue.destinationViewController;

        if ([underLeftViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController*)underLeftViewController;
            underLeftViewController = [navigationController.viewControllers firstObject];
        }

        if ([underLeftViewController isKindOfClass:[MITDrawerViewController class]]) {
            MITDrawerViewController *drawerViewController = (MITDrawerViewController*)underLeftViewController;
            drawerViewController.delegate = self;
        }
    }
}

#pragma mark Properties
- (UIBarButtonItem*)leftBarButtonItem
{
    UIImage *image = [UIImage imageNamed:MITImageBarButtonMenu];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(_showModuleSelector:)];
    return leftBarButtonItem;
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

- (MITDrawerViewController*)drawerViewController
{
    UIViewController *underLeftViewController = self.underLeftViewController;

    if ([underLeftViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController*)underLeftViewController;
        underLeftViewController = [navigationController.viewControllers firstObject];
    }

    if ([underLeftViewController isKindOfClass:[MITDrawerViewController class]]) {
        return (MITDrawerViewController*)underLeftViewController;
    } else {
        return nil;
    }

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

    if (_visibleViewController != newVisibleViewController) {
        if (![self.viewControllers containsObject:newVisibleViewController]) {
            MITModuleItem *moduleItem = newVisibleViewController.moduleItem;
            NSString *reason = [NSString stringWithFormat:@"view controller does not have a module with tag '%@'",moduleItem.name];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
        }

        NSAssert(self.topViewController, @"failed to load top view controller");

        UIViewController *oldVisibleViewController = _visibleViewController;
        _visibleViewController = newVisibleViewController;
        self.drawerViewController.selectedModuleItem = _visibleViewController.moduleItem;

        if (oldVisibleViewController) {
            [oldVisibleViewController willMoveToParentViewController:nil];

            [oldVisibleViewController beginAppearanceTransition:NO animated:NO];
            [oldVisibleViewController.view removeFromSuperview];
            [oldVisibleViewController endAppearanceTransition];
            
            [oldVisibleViewController removeFromParentViewController];
        }

        if (_visibleViewController) {
            // If the top view is a UINavigationController, automatically add a button to toggle the state
            // of the sliding view controller. Otherwise, the user must either use the pan gesture or the view
            // controller must do something itself.
            if ([_visibleViewController isKindOfClass:[UINavigationController class]]) {
                UINavigationController *navigationController = (UINavigationController*)_visibleViewController;
                UIViewController *rootViewController = [navigationController.viewControllers firstObject];

                if (!rootViewController.navigationItem.leftBarButtonItem) {
                    rootViewController.navigationItem.leftBarButtonItem = self.leftBarButtonItem;
                }
            }

            [self.topViewController addChildViewController:_visibleViewController];

            [_visibleViewController beginAppearanceTransition:YES animated:animated];
            [self.topViewController.view addSubview:_visibleViewController.view];
            [_visibleViewController endAppearanceTransition];

            [_visibleViewController didMoveToParentViewController:self.topViewController];
        }
    }

    if (self.currentTopViewPosition != ECSlidingViewControllerTopViewPositionCentered) {
        [self resetTopViewAnimated:animated];
    }
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

// Toggles the scrollsToTop state for the ECSlidingViewController.
// Since there may only be a single UIScrollView in the hierarchy and there
//   may be up to 3 UIViewController present in an ECSlidingViewController
//   (Top, Under-left, Under-right), whenever we update the top-most UIScrollView
//   (if one exists) in each view so that the active UIViewController has it's
//   top-most UIScrollView's scrollsToTop setting enabled, and the rest disabled.
//  If this is not done and there are multiple scroll views present, the scrollsToTop
//   is disabled for all the visible views.
// (bskinner - 2014.11.30)
- (void)_updateScrollsToTop
{
    UIViewController *scrollsToTopViewController = nil;

    switch (self.currentTopViewPosition) {
        case ECSlidingViewControllerTopViewPositionCentered: {
            scrollsToTopViewController = self.visibleViewController;
        } break;

        case ECSlidingViewControllerTopViewPositionAnchoredLeft: {
            scrollsToTopViewController = self.underRightViewController;
        } break;

        case ECSlidingViewControllerTopViewPositionAnchoredRight: {
            scrollsToTopViewController = self.underLeftViewController;
        }
    }

    void (^setScrollsToTop)(UIViewController *viewController, BOOL scrollsToTop) = ^(UIViewController *viewController, BOOL scrollsToTop) {
        BOOL stop = NO;
        NSMutableOrderedSet *subviews = [NSMutableOrderedSet orderedSetWithObject:viewController.view];
        while ([subviews count] && !stop) {
            UIView *view = [subviews firstObject];
            [subviews removeObject:view];

            if ([view isKindOfClass:[UIScrollView class]]) {
                UIScrollView *scrollView = (UIScrollView*)view;
                scrollView.scrollsToTop = scrollsToTop;
                stop = YES;
            } else if ([view.subviews count]) {
                [subviews addObjectsFromArray:view.subviews];
            }
        }
    };

    setScrollsToTop(scrollsToTopViewController,YES);

    NSMutableSet *scrollToTopDisabledViewControllers = [[NSMutableSet alloc] init];
    if (self.topViewController) {
        [scrollToTopDisabledViewControllers addObject:self.topViewController];
    }

    if (self.underLeftViewController) {
        [scrollToTopDisabledViewControllers addObject:self.underLeftViewController];
    }

    if (self.underRightViewController) {
        [scrollToTopDisabledViewControllers addObject:self.underRightViewController];
    }

    [scrollToTopDisabledViewControllers removeObject:scrollsToTopViewController];
    [scrollToTopDisabledViewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, BOOL *stop) {
        setScrollsToTop(viewController, NO);
    }];

}
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
