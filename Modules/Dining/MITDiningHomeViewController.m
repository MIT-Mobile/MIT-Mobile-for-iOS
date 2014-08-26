#import "MITDiningHomeViewController.h"
#import "MITDiningWebservices.h"
#import "MITDiningDining.h"
#import "MITDiningVenues.h"
#import "MITCoreData.h"
#import "MITAdditions.h"

#import "MITDiningHouseVenueListViewController.h"
#import "MITDiningRetailVenueListViewController.h"

@interface MITDiningHomeViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) UIBarButtonItem *menuBarButton;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) MITDiningDining *masterDiningData;

@property (nonatomic, strong) UISegmentedControl *houseRetailSelectorSegmentedControl;

@property (nonatomic, strong) MITDiningHouseVenueListViewController *houseListViewController;
@property (nonatomic, strong) MITDiningRetailVenueListViewController *retailListViewController;

@end

@implementation MITDiningHomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    [self setupNavigationBar];
    
    [self setupViewControllers];
    
    [self setupFetchedResultsController];
    [self performFetch];
    
    [self performWebserviceCall];

    [self setupSegmentedControl];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupNavigationBar
{
    self.edgesForExtendedLayout = UIRectEdgeNone;

    self.menuBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"global/menu.png"] style:UIBarButtonItemStylePlain target:self action:@selector(menuButtonPressed)];
    [self.navigationItem setLeftBarButtonItem:self.menuBarButton];

}

- (void)performWebserviceCall
{
    [MITDiningWebservices getDiningWithCompletion:NULL];
}

#pragma mark - Sub ViewController Management

- (void)setupViewControllers
{
    self.houseListViewController = [[MITDiningHouseVenueListViewController alloc] init];
    self.retailListViewController = [[MITDiningRetailVenueListViewController alloc] init];
    
    self.houseListViewController.view.frame =
    self.retailListViewController.view.frame = self.view.bounds;
    
    [self addChildViewController:self.houseListViewController];
    [self addChildViewController:self.retailListViewController];
   
    [self.view addSubview:self.houseListViewController.view];
    [self.view addSubview:self.retailListViewController.view];
    
    [self showHouseVenueList];
}

- (void)showHouseVenueList
{
    self.houseListViewController.view.hidden = NO;
    self.retailListViewController.view.hidden = YES;
}

- (void)showRetailVenueList
{
    self.houseListViewController.view.hidden = YES;
    self.retailListViewController.view.hidden = NO;
}

#pragma mark - Segmented Control

- (void)setupSegmentedControl
{
    self.houseRetailSelectorSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Dining Halls", @"Other"]];
    self.houseRetailSelectorSegmentedControl.selectedSegmentIndex = 0;
    [self.houseRetailSelectorSegmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.houseRetailSelectorSegmentedControl;
}

- (void)segmentedControlValueChanged:(UISegmentedControl *)segmentedControl
{
    if (segmentedControl.selectedSegmentIndex == 0) {
        [self showHouseVenueList];
    }
    else {
        [self showRetailVenueList];
    }
}

#pragma mark - Fetched Results Controller

- (void)setupFetchedResultsController
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MITDiningDining"
                                              inManagedObjectContext:[[MITCoreDataController defaultController] mainQueueContext]];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"url"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    NSFetchedResultsController *fetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:[[MITCoreDataController defaultController] mainQueueContext]
                                          sectionNameKeyPath:nil
                                                   cacheName:nil];
    self.fetchedResultsController = fetchedResultsController;
    _fetchedResultsController.delegate = self;
}

- (void)performFetch
{
    [self.fetchedResultsController performFetch:nil];
   
    [self controllerDidChangeContent:self.fetchedResultsController];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (self.fetchedResultsController.fetchedObjects.count > 0) {
        // We should only ever have one dining object in the fetched results
        self.masterDiningData = self.fetchedResultsController.fetchedObjects[0];
        [self updateDataInSubViewControllers];
    }
}

- (void)updateDataInSubViewControllers
{
    self.houseListViewController.diningData = self.masterDiningData;
    self.retailListViewController.retailVenues = [self.masterDiningData.venues.retail array];
}

- (void)menuButtonPressed
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
