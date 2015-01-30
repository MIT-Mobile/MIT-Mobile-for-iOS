#import "MITMartyRootPhoneViewController.h"
#import "MITMartyResourceDataSource.h"
#import "MITMartyModel.h"
#import "MITMartyDetailTableViewController.h"

@interface MITMartyRootPhoneViewController ()
@property(nonatomic,weak) IBOutlet NSLayoutConstraint *topViewHeightConstraint;
@property(nonatomic,strong) MITMartyResourceDataSource *dataSource;
@property(nonatomic,readonly,strong) NSArray *resources;
@property (nonatomic, strong) MITMartyResource *resource;

@end

@implementation MITMartyRootPhoneViewController

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
    [dataSource resourcesWithQuery:@"Slant-Bed+CNC+Lathe" completion:^(MITMartyResourceDataSource *dataSource, NSError *error) {
        if (error) {
            DDLogWarn(@"Error: %@",error);
        } else {
            [self.managedObjectContext performBlockAndWait:^{
                [self.managedObjectContext reset];

                [self.resources enumerateObjectsUsingBlock:^(MITMartyResource *resource, NSUInteger idx, BOOL *stop) {
                    DDLogVerbose(@"Got resource with name: %@ [%@]",resource.name, resource.identifier);
                    if ([resource.name isEqualToString:@"Slant-Bed CNC Lathe"]) {
                        self.resource = resource;
                        [self performSegueWithIdentifier:@"showDetail" sender:nil];
                        *stop = YES;
                        
                    }
                }];

            }];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Public Properties
- (NSArray*)resources
{
    __block NSArray *resourceObjects = nil;
    [self.managedObjectContext performBlockAndWait:^{
        resourceObjects = [self.managedObjectContext transferManagedObjects:self.dataSource.resources];
    }];

    return resourceObjects;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *destinationViewController = [segue destinationViewController];
    
    DDLogVerbose(@"Performing segue with identifier '%@'",[segue identifier]);
    
    if ([segue.identifier isEqualToString:@"showDetail"]) {
        if ([destinationViewController isKindOfClass:[MITMartyDetailTableViewController class]]) {
            
            if (self.resource) {
                MITMartyDetailTableViewController *storyDetailViewController = (MITMartyDetailTableViewController*)destinationViewController;
                storyDetailViewController.resource = self.resource;
            }
        } else {
            DDLogWarn(@"unexpected class for segue %@. Expected %@ but got %@",segue.identifier,
                      NSStringFromClass([MITMartyDetailTableViewController class]),
                      NSStringFromClass([[segue destinationViewController] class]));
        }
    }
}

@end
