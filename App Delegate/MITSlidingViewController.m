#import "MITSlidingViewController.h"
#import "MITAdditions.h"
#import "MITModule.h"
#import "MITDrawerViewController.h"

static NSString* const MITRootLogoHeaderReuseIdentifier = @"RootLogoHeaderReuseIdentifier";

@interface MITSlidingViewController () <ECSlidingViewControllerDelegate>
@property(nonatomic,readonly) MITDrawerViewController *drawerViewController;
@property(nonatomic,weak) id<UIViewControllerAnimatedTransitioning,ECSlidingViewControllerLayout> animationController;
@end

@implementation MITSlidingViewController
@dynamic drawerViewController;

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!([self.modules count] > 0)) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"drawer view controller must have at least 1 view controller added before being presented" userInfo:nil];
    }

    [self _showInitialModuleIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGestureTapping | ECSlidingViewControllerAnchoredGesturePanning;
    self.customAnchoredGestures = @[];
}

#pragma mark Properties
- (MITDrawerViewController*)drawerViewController
{
    if ([self.underLeftViewController isKindOfClass:[MITDrawerViewController class]]) {
        return (MITDrawerViewController*)self.underLeftViewController;
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

- (void)setVisibleModule:(MITModule*)module withViewController:(UIViewController*)viewController
{
    if (!viewController) {
        viewController = [[UIViewController alloc] init];
        viewController.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        viewController.view.backgroundColor = [UIColor mit_backgroundColor];
    }

    _visibleModule = module;
    self.drawerViewController.selectedModule = module;
    
    if (self.topViewController != viewController) {
        [self.topViewController.view removeGestureRecognizer:self.panGesture];
        [self setTopViewController:viewController];
    }
    
    [self resetTopViewAnimated:YES onComplete:^{
        if (![self.topViewController.view.gestureRecognizers containsObject:self.panGesture]) {
            [self.topViewController.view addGestureRecognizer:self.panGesture];
        }
    }];
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

@end
