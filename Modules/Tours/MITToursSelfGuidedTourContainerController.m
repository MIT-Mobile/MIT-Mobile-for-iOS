#import "MITToursSelfGuidedTourContainerController.h"
#import "MITToursSelfGuidedTourListViewController.h"
#import "MITToursSelfGuidedTourInfoViewController.h"
#import "MITToursMapViewController.h"
#import "MITToursStopDetailContainerViewController.h"

typedef NS_ENUM(NSInteger, MITToursSelfGuidedTour) {
    MITToursSelfGuidedTourMap,
    MITToursSelfGuidedTourList
};

@interface MITToursSelfGuidedTourContainerController () <MITToursSelfGuidedTourListViewControllerDelegate>

@property (nonatomic, strong) MITToursMapViewController *mapViewController;
@property (nonatomic, strong) MITToursSelfGuidedTourListViewController *listViewController;

@property (nonatomic, strong) UISegmentedControl *mapListSegmentedControl;
@property (nonatomic, strong) UIBarButtonItem *currentLocationButton;

@end

@implementation MITToursSelfGuidedTourContainerController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Self-Guided Tour";
    
    [self setupViewControllers];
    
    [self setupNavBar];
    
    [self setupToolbar];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO];
}

- (void)setupViewControllers
{
    self.listViewController = [[MITToursSelfGuidedTourListViewController alloc] init];
    self.listViewController.tour = self.selfGuidedTour;
    self.listViewController.delegate = self;

    self.mapViewController = [[MITToursMapViewController alloc] initWithTour:self.selfGuidedTour nibName:nil bundle:nil];
        
    self.listViewController.view.frame =
    self.mapViewController.view.frame = self.view.bounds;
    
    [self addChildViewController:self.listViewController];
    [self addChildViewController:self.mapViewController];
    
    [self.view addSubview:self.listViewController.view];
    [self.view addSubview:self.mapViewController.view];
}

- (void)setupNavBar
{
    UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithTitle:@"Info" style:UIBarButtonItemStylePlain target:self action:@selector(infoButtonPressed:)];
    self.navigationItem.rightBarButtonItem = infoButton;
    
    // Following screens should have no "Back" text on back button
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backItem;
}

- (void)setupToolbar
{
    self.mapListSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Map", @"List"]];
    [self.mapListSegmentedControl addTarget:self action:@selector(showSelectedViewController) forControlEvents:UIControlEventValueChanged];
    [self.mapListSegmentedControl setWidth:90.0 forSegmentAtIndex:0];
    [self.mapListSegmentedControl setWidth:90.0 forSegmentAtIndex:1];
    
    [self.mapListSegmentedControl setSelectedSegmentIndex:0];
    
    UIBarButtonItem *segmentedControlItem = [[UIBarButtonItem alloc] initWithCustomView:self.mapListSegmentedControl];
    UIBarButtonItem *currentLocationButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map/map_location"]
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(currentLocationButtonPressed:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[currentLocationButtonItem, flexibleSpace, segmentedControlItem, flexibleSpace];

    self.currentLocationButton = currentLocationButtonItem;
}

- (void)showSelectedViewController
{
    switch (self.mapListSegmentedControl.selectedSegmentIndex) {
        case MITToursSelfGuidedTourMap:
            [self showMapViewController];
            break;
        case MITToursSelfGuidedTourList:
            [self showListViewController];
            break;
        default:
            break;
    }
}

- (void)showMapViewController
{
    self.listViewController.view.hidden = YES;
    self.mapViewController.view.hidden = NO;
    [self showCurrentLocationButton];
}

- (void)showListViewController
{
    self.mapViewController.view.hidden = YES;
    self.listViewController.view.hidden = NO;
    [self hideCurrentLocationButton];
}

- (void)infoButtonPressed:(id)sender
{
    MITToursSelfGuidedTourInfoViewController *infoVC = [[MITToursSelfGuidedTourInfoViewController alloc] init];
    infoVC.tour = self.selfGuidedTour;
    [self.navigationController pushViewController:infoVC animated:YES];
}

#pragma mark - Current Location Button

- (void)showCurrentLocationButton
{
    NSMutableArray *items = [self.toolbarItems mutableCopy];
    if (![items containsObject:self.currentLocationButton]) {
        [items insertObject:self.currentLocationButton atIndex:0];
        [self setToolbarItems:items animated:YES];
    }
}

- (void)hideCurrentLocationButton
{
    NSMutableArray *items = [self.toolbarItems mutableCopy];
    if ([items containsObject:self.currentLocationButton]) {
        [items removeObject:self.currentLocationButton];
        [self setToolbarItems:items animated:YES];
    }
}

- (void)currentLocationButtonPressed:(id)sender
{
    [self.mapViewController centerMapOnUserLocation];
}

#pragma mark - MITToursSelfGuidedTourListViewControllerDelegate Methods

- (void)selfGuidedTourListViewController:(MITToursSelfGuidedTourListViewController *)selfGuidedTourListViewController didSelectStop:(MITToursStop *)stop
{
    MITToursStopDetailContainerViewController *stopDetailContainerViewController = [[MITToursStopDetailContainerViewController alloc] initWithTour:self.selfGuidedTour stop:stop nibName:nil bundle:nil];
    [self.navigationController pushViewController:stopDetailContainerViewController animated:YES];
}

@end
