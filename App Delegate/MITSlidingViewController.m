#import "MITSlidingViewController.h"
#import "MITAdditions.h"
#import "MITModule.h"
#import "MITDrawerViewController.h"

static NSString* const MITRootLogoHeaderReuseIdentifier = @"RootLogoHeaderReuseIdentifier";

@interface MITSlidingViewController () <UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,readonly) MITDrawerViewController *drawerViewController;
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
    self.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGestureTapping;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!([self.modules count] > 0)) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"drawer view controller must have at least 1 view controller added before being presented" userInfo:nil];
    }

    [self _showInitialModuleIfNeeded];
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

    _visibleModule = module;
    [self setVisibleViewController:module.homeViewController];
}

- (void)setVisibleModuleWithTag:(NSString *)moduleTag
{
    __block MITModule *selectedModule = nil;
    [self.modules enumerateObjectsUsingBlock:^(MITModule *module, NSUInteger idx, BOOL *stop) {
        if ([module.tag isEqualToString:moduleTag]) {
            selectedModule = module;
            (*stop) = YES;
        }
    }];

    [self setVisibleModule:selectedModule];
}

- (BOOL)setVisibleModuleWithNotification:(MITNotification *)notification
{
    
}

- (BOOL)setVisibleModuleWithURL:(NSURL *)url
{

}

- (void)setVisibleViewController:(UIViewController*)viewController
{
    if (!viewController) {
        viewController = [[UIViewController alloc] init];
        viewController.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        viewController.view.backgroundColor = [UIColor mit_backgroundColor];
    }

    [self setTopViewController:viewController];
}

- (id<UIViewControllerTransitionCoordinator>)transitionCoordinator
{
    return nil;
}

#pragma mark Private
- (void)_showInitialModuleIfNeeded
{
    if (!self.visibleModule) {
        self.visibleModule = [self.modules firstObject];
    }
}
@end
