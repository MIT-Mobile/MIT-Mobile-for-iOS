#import "MITDiningRetailVenueListViewController.h"
#import "MITDiningHouseVenueListViewController.h"
#import "MITDiningRefreshDataProtocols.h"
#import "MITDiningHomeViewController.h"
#import "MITDiningMapsViewController.h"
#import "MITDiningWebservices.h"
#import "MITDiningDining.h"
#import "MITDiningVenues.h"
#import "MITAdditions.h"
#import "MITCoreData.h"
#import "MITSlidingViewController.h"

@interface MITDiningHomeViewController () <NSFetchedResultsControllerDelegate, MITDiningRefreshRequestDelegate>

@property (nonatomic, strong) UIBarButtonItem *menuBarButton;
@property (nonatomic, strong) UIBarButtonItem *mapBarButton;
@property (nonatomic, strong) UIBarButtonItem *listBarButton;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) MITDiningDining *masterDiningData;

@property (nonatomic, strong) UISegmentedControl *houseRetailSelectorSegmentedControl;

@property (nonatomic, strong) MITDiningHouseVenueListViewController *houseListViewController;
@property (nonatomic, strong) MITDiningRetailVenueListViewController *retailListViewController;
@property (nonatomic, strong) MITDiningMapsViewController *mapViewController;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

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
    [self.activityIndicator startAnimating];
    
    [self setupNavigationBar];
    
    [self setupViewControllers];
    
    [self setupFetchedResultsController];
    [self performFetch];

    [self setupSegmentedControl];
    
    [self performWebserviceCall];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupNavigationBar
{
    self.edgesForExtendedLayout = UIRectEdgeNone;

    [self.navigationItem setLeftBarButtonItem:[MIT_MobileAppDelegate applicationDelegate].rootViewController.leftBarButtonItem];
    
    self.mapBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStylePlain target:self action:@selector(mapButtonPressed)];
    [self.navigationItem setRightBarButtonItem:self.mapBarButton];
    // Yes, having two bar button items is silly, but switching between them looks a lot better than changing the title of a single button for some reason.
    self.listBarButton = [[UIBarButtonItem alloc] initWithTitle:@"List" style:UIBarButtonItemStylePlain target:self action:@selector(mapButtonPressed)];
}

- (void)performWebserviceCall
{
    [MITDiningWebservices getDiningWithCompletion:^(MITDiningDining *dining, NSError *error) {
        [self performFetch];
    }];
}

#pragma mark - Sub ViewController Management

- (void)setupViewControllers
{
    self.houseListViewController = [[MITDiningHouseVenueListViewController alloc] init];
    self.retailListViewController = [[MITDiningRetailVenueListViewController alloc] init];
    self.mapViewController = [[MITDiningMapsViewController alloc] init];
    
    self.houseListViewController.refreshDelegate = self;
    self.retailListViewController.refreshDelegate = self;
    
    self.houseListViewController.view.frame =
    self.retailListViewController.view.frame =
    self.mapViewController.view.frame = self.view.bounds;
    
    [self.mapViewController setToolBarHidden:NO];
    
    [self addChildViewController:self.houseListViewController];
    [self addChildViewController:self.retailListViewController];
    [self addChildViewController:self.mapViewController];
   
    [self.view addSubview:self.houseListViewController.view];
    [self.view addSubview:self.retailListViewController.view];
    [self.view addSubview:self.mapViewController.view];
    
    [self.view bringSubviewToFront:self.activityIndicator];
    
    [self.houseListViewController didMoveToParentViewController:self];
    [self.retailListViewController didMoveToParentViewController:self];
    [self.mapViewController didMoveToParentViewController:self];
    
    [self showHouseVenueList];
}

- (void)showHouseVenueList
{
    self.retailListViewController.view.hidden = YES;
    self.mapViewController.view.hidden = YES;
    self.houseListViewController.view.hidden = NO;
}

- (void)showRetailVenueList
{
    self.houseListViewController.view.hidden = YES;
    self.mapViewController.view.hidden = YES;
    self.retailListViewController.view.hidden = NO;
}

- (void)showMapView
{
    self.houseListViewController.view.hidden = YES;
    self.retailListViewController.view.hidden = YES;
    self.mapViewController.view.hidden = NO;
}

#pragma mark - Segmented Control

- (void)setupSegmentedControl
{
    self.houseRetailSelectorSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"House Dining", @"Retail"]];
    self.houseRetailSelectorSegmentedControl.selectedSegmentIndex = 0;
    [self.houseRetailSelectorSegmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.houseRetailSelectorSegmentedControl;
}

- (void)segmentedControlValueChanged:(UISegmentedControl *)segmentedControl
{
    if (self.mapViewController.view.hidden) {
        if (self.houseRetailSelectorSegmentedControl.selectedSegmentIndex == 0) {
            [self showHouseVenueList];
        } else {
            [self showRetailVenueList];
        }
    } else {
        if (self.houseRetailSelectorSegmentedControl.selectedSegmentIndex == 0) {
            [self.mapViewController updateMapWithDiningPlaces:[self.masterDiningData.venues.house array]];
        } else {
            [self.mapViewController updateMapWithDiningPlaces:[self.masterDiningData.venues.retail array]];
        }
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
        NSArray *orderedVenues = [self.masterDiningData.venues.house sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"shortName" ascending:YES]]];
        self.masterDiningData.venues.house = [NSOrderedSet orderedSetWithArray:orderedVenues];

        [self updateDataInSubViewControllers];
    }
}

- (void)updateDataInSubViewControllers
{
    [self.activityIndicator stopAnimating];
    self.houseListViewController.diningData = self.masterDiningData;
    self.retailListViewController.retailVenues = [self.masterDiningData.venues.retail array];
}

#pragma mark - Navbar Button Actions
- (void)mapButtonPressed
{
    if (self.mapViewController.view.hidden) {
        [self.navigationItem setRightBarButtonItem:self.listBarButton animated:YES];
        [self showMapView];
        if (self.houseRetailSelectorSegmentedControl.selectedSegmentIndex == 0) {
            [self.mapViewController updateMapWithDiningPlaces:[self.masterDiningData.venues.house array]];
        } else {
            [self.mapViewController updateMapWithDiningPlaces:[self.masterDiningData.venues.retail array]];
        }
    } else {
        [self.navigationItem setRightBarButtonItem:self.mapBarButton animated:YES];
        if (self.houseRetailSelectorSegmentedControl.selectedSegmentIndex == 0) {
            [self showHouseVenueList];
        } else {
            [self showRetailVenueList];
        }
    }
}

#pragma mark - Refreshing Delegate
- (void)viewControllerRequestsDataUpdate:(UIViewController<MITDiningRefreshableViewController> *)viewController{
    [MITDiningWebservices getDiningWithCompletion:^(MITDiningDining *dining, NSError *error) {
        [viewController refreshRequestComplete];
    }];
}

@end
