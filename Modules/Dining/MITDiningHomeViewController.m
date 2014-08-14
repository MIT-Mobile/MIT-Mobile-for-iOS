#import "MITDiningHomeViewController.h"
#import "MITDiningWebservices.h"
#import "MITDiningDining.h"
#import "MITCoreData.h"
#import "MITAdditions.h"

#import "MITDiningHouseVenueListViewController.h"
#import "MITDiningRetailVenueListViewController.h"

@interface MITDiningHomeViewController () <NSFetchedResultsControllerDelegate>

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
 
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self performWebserviceCall];

    [self setupViewControllers];
    [self setupSegmentedControl];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

@end
