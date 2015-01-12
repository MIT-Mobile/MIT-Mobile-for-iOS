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

static CGFloat const MITSlidingViewControllerDefaultAnchorLeftRevealAmountPad = 270.;

// This number was picked in order to have an equal amount of whitespace on either
// side of the leftBarButtonIcon. 54pt results in having 14pt of whitespace on either side.
// This was tested on iOS 8 and iOS 7
// (bskinner - 2014.11.14)
static CGFloat const MITSlidingViewControllerDefaultAnchorRightPeekAmountPhone = 54.;


@interface MITSlidingViewController () <ECSlidingViewControllerDelegate,UINavigationControllerDelegate,MITDrawerViewControllerDelegate,UIGestureRecognizerDelegate>
@property(nonatomic,weak) MITDrawerViewController *drawerViewController;
@property(nonatomic,strong) UIBarButtonItem *leftBarButtonItem;

@property(nonatomic,weak) MITSlidingAnimationController *animationController;

@end

@implementation MITSlidingViewController {

    // YES if the currently visible module was presented modally
    BOOL _visibleViewControllerIsModal;

    // Used to keep track of the currently visible view controller.
    // The visibleViewController ivar only keeps track of what view controller
    //  should be displayed. When the view controller is actually presented to
    //  the user, the _currentVisibleViewController ivar is updated with the
    //  proper value
    // (bskinner - 2014.12.05)
    __weak UIViewController *_currentVisibleViewController;

    // Keeps track of the last non-modal visible view controller.
    // When a modal module is presented, this is set to the last
    //  full-screen module that was displayed (which will still
    //  be visible behind the modal view). When the modal view
    //  is dismissed, this is the module that will be restored
    //  as the selected one.
    // (bskinner - 2014.12.06)
    __weak UIViewController *_lastPrimaryVisibleViewController;

    __weak UIGestureRecognizer *_modalDismissGestureRecognizer;
}

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
    [super viewDidLoad];

    self.drawerViewController.moduleItems = [self _moduleItems];
    
    self.panGesture.maximumNumberOfTouches = 1;
    self.panGesture.delegate = self;
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
            self.anchorLeftRevealAmount = MITSlidingViewControllerDefaultAnchorLeftRevealAmountPad;
        } break;

        default: {
            // Leave it alone
        } break;
    }

    if (!self.visibleViewController) {
        [self setVisibleViewController:[self.viewControllers firstObject] animated:animated];
    }

    [self _presentVisibleViewControllerIfNeeded:animated completion:nil];
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

- (UIViewController*)underLeftViewController
{
    UIViewController *underLeftViewController = [super underLeftViewController];

    if (!underLeftViewController) {
        [self performSegueWithIdentifier:MITSlidingViewControllerUnderLeftSegueIdentifier sender:self];
        underLeftViewController = [super underLeftViewController];
    }

    return underLeftViewController;
}

- (UIViewController*)topViewController
{
    UIViewController *topViewController = [super topViewController];

    if (!topViewController) {
        [self performSegueWithIdentifier:MITSlidingViewControllerTopSegueIdentifier sender:self];
        topViewController = [super topViewController];
    }

    return topViewController;
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

        [self.drawerViewController setModuleItems:[self _moduleItems] animated:animated];
        [self.drawerViewController setSelectedModuleItem:self.visibleViewController.moduleItem animated:animated];

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
        }
    }
}

- (void)setVisibleViewController:(UIViewController*)visibleViewController
{
    [self setVisibleViewController:visibleViewController animated:NO];
}

- (void)setVisibleViewController:(UIViewController*)newVisibleViewController animated:(BOOL)animated
{
    [self setVisibleViewController:newVisibleViewController animated:animated completion:nil];
}

- (void)setVisibleViewController:(UIViewController*)newVisibleViewController animated:(BOOL)animated completion:(void(^)(void))completion
{
    NSParameterAssert(newVisibleViewController);

    if (_visibleViewController != newVisibleViewController) {
        if (![self.viewControllers containsObject:newVisibleViewController]) {
            MITModuleItem *moduleItem = newVisibleViewController.moduleItem;
            NSString *reason = [NSString stringWithFormat:@"view controller does not have a module with tag '%@'",moduleItem.name];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
        }

        _visibleViewController = newVisibleViewController;
        self.drawerViewController.selectedModuleItem = self.visibleViewController.moduleItem;
    }

    [self _presentVisibleViewControllerIfNeeded:animated completion:^{
        if (self.currentTopViewPosition != ECSlidingViewControllerTopViewPositionCentered) {
            [self resetTopViewAnimated:animated];
        }

        if (completion) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion();
            }];
        }
    }];
}

- (void)_presentVisibleViewControllerIfNeeded:(BOOL)animated completion:(void(^)(void))completion
{
    if (_currentVisibleViewController != self.visibleViewController) {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            if (self.visibleViewController.moduleItem.type == MITModulePresentationFullScreen) {
                [self _presentTopVisibleViewController:animated completion:completion];
            } else if (self.visibleViewController.moduleItem.type == MITModulePresentationModal) {
                [self _presentModalVisibleViewController:animated completion:completion];
            }
        } else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            [self _presentTopVisibleViewController:animated completion:completion];
        }
    }
}

- (void)setVisibleViewControllerWithModuleName:(NSString *)name
{
    UIViewController *moduleViewController = [self _moduleViewControllerWithName:name];
    
    if (!moduleViewController) {
        self.visibleViewController = [self.viewControllers firstObject];
    } else {
        self.visibleViewController = moduleViewController;
    }
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
- (NSArray*)_moduleItems
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

- (IBAction)_showModuleSelector:(id)sender
{
    [self showModuleSelector:YES completion:nil];
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

    if (![self isViewLoaded]) {
        return;
    }

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

    NSMutableSet *scrollToTopDisabledViewControllers = [[NSMutableSet alloc] init];
    if (self.visibleViewController) {
        [scrollToTopDisabledViewControllers addObject:self.visibleViewController];
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

    setScrollsToTop(scrollsToTopViewController,YES);

}

- (IBAction)_handleModalDismissGesture:(UIGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint point = [sender locationInView:sender.view.window];
        CGRect modalFrame = [self.visibleViewController.view convertRect:self.visibleViewController.view.bounds toView:sender.view.window];

        if (!CGRectContainsPoint(modalFrame, point)) {
            MITModuleItem *primaryModuleItem = _lastPrimaryVisibleViewController.moduleItem;
            _lastPrimaryVisibleViewController = nil;

            [_modalDismissGestureRecognizer.view removeGestureRecognizer:_modalDismissGestureRecognizer];
            _modalDismissGestureRecognizer = nil;

            [self _showModuleWithModuleItem:primaryModuleItem animated:YES];
        }
    }
}

- (void)_showModuleWithModuleItem:(MITModuleItem*)moduleItem animated:(BOOL)animated
{
    NSParameterAssert(moduleItem);

    UIViewController *moduleViewController = [self _moduleViewControllerWithName:moduleItem.name];
    NSAssert(moduleViewController,@"module with name %@ does not have an associated view controller.",moduleItem.name);

    [self _willHideTopViewController:self.visibleViewController];
    __weak MITSlidingViewController *weakSelf = self;
    [self setVisibleViewController:moduleViewController animated:animated completion:^{
        MITSlidingViewController *blockSelf = weakSelf;
        [blockSelf _didShowTopViewController:blockSelf.visibleViewController];
    }];
}

#pragma mark View Controller management
- (void)_presentTopVisibleViewController:(BOOL)animated completion:(void(^)(void))block
{
    void (^presentVisibleViewController)(UIViewController *viewController) = ^(UIViewController *viewController) {
        // If the top view is a UINavigationController, automatically add a button to toggle the state
        // of the sliding view controller. Otherwise, the user must either use the pan gesture or the view
        // controller must do something itself.
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController*)viewController;
            UIViewController *rootViewController = [navigationController.viewControllers firstObject];

            if (!rootViewController.navigationItem.leftBarButtonItem) {
                rootViewController.navigationItem.leftBarButtonItem = self.leftBarButtonItem;
            }
        }

        [self.topViewController addChildViewController:viewController];

        viewController.view.frame = self.topViewController.view.bounds;

        [viewController beginAppearanceTransition:YES animated:animated];
        [self.topViewController.view addSubview:viewController.view];
        [viewController endAppearanceTransition];

        [viewController didMoveToParentViewController:self.topViewController];

        _currentVisibleViewController = viewController;
        _lastPrimaryVisibleViewController = viewController;
        _visibleViewControllerIsModal = NO;
        [self _updateScrollsToTop];

        if (block) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                block();
            }];
        }
    };

    if (_visibleViewControllerIsModal) {
        [self.topViewController dismissViewControllerAnimated:YES completion:^{
            presentVisibleViewController(self.visibleViewController);
        }];
    } else {
        [_currentVisibleViewController willMoveToParentViewController:nil];

        [_currentVisibleViewController beginAppearanceTransition:NO animated:animated];
        [_currentVisibleViewController.view removeFromSuperview];
        [_currentVisibleViewController endAppearanceTransition];

        [_currentVisibleViewController removeFromParentViewController];

        presentVisibleViewController(self.visibleViewController);
    }
}

- (void)_presentModalVisibleViewController:(BOOL)animated completion:(void(^)(void))block
{
    self.visibleViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    self.visibleViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    self.visibleViewController.view.tintColor = self.view.tintColor;

    void (^completionBlock)(void) = ^{
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] init];
        [tapGestureRecognizer addTarget:self action:@selector(_handleModalDismissGesture:)];
        tapGestureRecognizer.cancelsTouchesInView = NO;
        tapGestureRecognizer.delegate = self;
        [self.visibleViewController.view.window addGestureRecognizer:tapGestureRecognizer];

        _modalDismissGestureRecognizer = tapGestureRecognizer;
        _currentVisibleViewController = self.visibleViewController;
        _visibleViewControllerIsModal = YES;
        [self _updateScrollsToTop];

        if (block) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                block();
            }];
        }
    };

    if (_visibleViewControllerIsModal) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self.topViewController presentViewController:self.visibleViewController animated:animated completion:completionBlock];
        }];
    } else {
        [self presentViewController:self.visibleViewController animated:animated completion:completionBlock];
    }
}

#pragma mark Delegation
- (void)drawerViewController:(MITDrawerViewController *)drawerViewController didSelectModuleItem:(MITModuleItem *)moduleItem
{
    [self _showModuleWithModuleItem:moduleItem animated:YES];
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == _modalDismissGestureRecognizer) {
        CGRect modalFrame = [self.view convertRect:_visibleViewController.view.bounds fromView:_visibleViewController.view];
        CGPoint touchLocation = [touch locationInView:self.view];
        return !CGRectContainsPoint(modalFrame, touchLocation) && !_visibleViewController.presentedViewController;
    } else if (gestureRecognizer == self.panGesture) {
        UIPanGestureRecognizer *panGesture = self.panGesture;
        
        if (panGesture.state != UIGestureRecognizerStatePossible) {
            return YES;
        }
        
        CGRect navigationBarFrame = CGRectNull;
        if ([self.visibleViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController*)self.visibleViewController;
            if (!navigationController.isNavigationBarHidden) {
                navigationBarFrame = navigationController.navigationBar.bounds;
                navigationBarFrame = [self.view convertRect:navigationBarFrame fromView:navigationController.navigationBar];
            }
        }
        
        CGRect screenEdgeRect = [self.view convertRect:self.topViewController.view.bounds fromView:self.topViewController.view];
        screenEdgeRect.size.width = CGRectGetHeight([[UIApplication sharedApplication] statusBarFrame]);
        
        CGPoint touchLocation = [touch locationInView:self.view];
        return (CGRectContainsPoint(screenEdgeRect, touchLocation) || CGRectContainsPoint(navigationBarFrame, touchLocation));
    } else {
        return NO;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return (gestureRecognizer == _modalDismissGestureRecognizer) || (gestureRecognizer == self.panGesture);
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return ((gestureRecognizer == _modalDismissGestureRecognizer) || (gestureRecognizer == self.panGesture));
}

#pragma mark - Rotation

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if ([self actualTopVC]) {
        return [[self actualTopVC] preferredInterfaceOrientationForPresentation];
    } else {
        return [super preferredInterfaceOrientationForPresentation];
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([self actualTopVC]) {
        return [[self actualTopVC] supportedInterfaceOrientations];
    } else {
        return [super supportedInterfaceOrientations];
    }
}

- (BOOL)shouldAutorotate
{
    if ([self actualTopVC]) {
        return [[self actualTopVC] shouldAutorotate];
    } else {
        return [self shouldAutorotate];
    }
}

- (UIViewController *)actualTopVC
{
    UIViewController *vc = self.visibleViewController;
    if (vc) {
        if ([vc isKindOfClass:[UINavigationController class]]) {
            return [(UINavigationController *)vc topViewController];
        } else {
            return vc;
        }
    } else {
        return nil;
    }
}

#pragma mark MITSlidingViewControllerDelegate pass-throughs
- (void)_willHideTopViewController:(UIViewController*)viewController
{
    if ([self.delegate respondsToSelector:@selector(slidingViewController:willHideTopViewController:)]) {
        [self.delegate slidingViewController:self willHideTopViewController:viewController];
    }
}

- (void)_didShowTopViewController:(UIViewController*)viewController
{
    if ([self.delegate respondsToSelector:@selector(slidingViewController:didShowTopViewController:)]) {
        [self.delegate slidingViewController:self didShowTopViewController:viewController];
    }
}

@end
