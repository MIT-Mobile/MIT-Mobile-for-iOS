#import "MITMartyRootPhoneViewController.h"
#import "MITMartyResourceDataSource.h"
#import "MITMartyModel.h"
#import "MITMartyResourcesTableViewController.h"

@interface MITMartyRootPhoneViewController () <MITMartyResourcesTableViewControllerDelegate>
@property(nonatomic,weak) IBOutlet NSLayoutConstraint *topViewHeightConstraint;
@property(nonatomic,strong) MITMartyResourceDataSource *dataSource;
@property(nonatomic,readonly,strong) NSArray *resources;

@property(nonatomic,readonly,weak) MITMartyResource *resource;
@property(nonatomic,readonly,weak) MITMartyResourcesTableViewController *resourcesTableViewController;
@end

@implementation MITMartyRootPhoneViewController
@synthesize resource = _resource;
@synthesize resourcesTableViewController = _resourcesTableViewController;

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.managedObjectContext) {
        self.managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:YES];
    }

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    MITMartyResourceDataSource *dataSource = [[MITMartyResourceDataSource alloc] init];
    self.dataSource = dataSource;
    [dataSource resourcesWithQuery:@"lathe" completion:^(MITMartyResourceDataSource *dataSource, NSError *error) {
        if (error) {
            DDLogWarn(@"Error: %@",error);
        } else {
            [self.managedObjectContext performBlockAndWait:^{
                [self.managedObjectContext reset];
                
                self.resourcesTableViewController.resources = self.resources;
            }];
        }
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Public Properties
- (MITMartyResourcesTableViewController*)resourcesTableViewController
{
    if (!_resourcesTableViewController) {
        MITMartyResourcesTableViewController *resourcesTableViewController = [[MITMartyResourcesTableViewController alloc] init];
        resourcesTableViewController.delegate = self;
        
        [self addChildViewController:resourcesTableViewController];
        [resourcesTableViewController beginAppearanceTransition:YES animated:NO];
        [self.tableViewContainer addSubview:resourcesTableViewController.view];
        [resourcesTableViewController endAppearanceTransition];
        [resourcesTableViewController didMoveToParentViewController:self];
        
        _resourcesTableViewController = resourcesTableViewController;
    }
    
    return _resourcesTableViewController;
}

- (NSArray*)resources
{
    __block NSArray *resourceObjects = nil;
    [self.managedObjectContext performBlockAndWait:^{
        resourceObjects = [self.managedObjectContext transferManagedObjects:self.dataSource.resources];
    }];

    return resourceObjects;
}

#pragma mark Delegation
- (void)resourcesTableViewController:(MITMartyResourcesTableViewController *)tableViewController didSelectResource:(MITMartyResource *)resource
{
    
}

@end
