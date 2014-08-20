#import "MITRootViewController.h"
#import "ECSlidingViewController.h"
#import "MITModule.h"
#import "MITLauncherListViewController.h"
#import "MITNavigationController.h"

#import "MITAdditions.h"

@interface MITRootViewController () <ECSlidingViewControllerDelegate,ECSlidingViewControllerLayout,UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,strong) NSArray *availableModules;
@property (nonatomic,weak) MITModule *lastSelectedModule;

@property (nonatomic,weak) ECSlidingViewController *slidingViewController;
@property (nonatomic,weak) UITableViewController *leftDrawerViewController;
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
    [self.leftDrawerViewController.tableView reloadData];
}

- (void)_presentModule:(MITModule*)module animated:(BOOL)animated
{
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
        [self _presentModule:newActiveModule animated:animated];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark Lazy Getters
- (UITableViewController*)leftDrawerViewController
{
    UITableViewController *tableViewController = _leftDrawerViewController;

    if (!tableViewController) {
        tableViewController = [[UITableViewController alloc] init];
        tableViewController.tableView.delegate = self;
        tableViewController.tableView.dataSource = self;
    }
}

- (ECSlidingViewController*)slidingViewController
{

}

#pragma mark Delegation
#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.modules count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark UITableViewDelegate

@end
