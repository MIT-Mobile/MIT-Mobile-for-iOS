#import "MITToursSelfGuidedTourContainerController.h"
#import "MITToursSelfGuidedTourListViewController.h"
#import "MITToursTourDetailsViewController.h"
#import "MITToursMapViewController.h"
#import "MITToursStopDetailContainerViewController.h"

typedef NS_ENUM(NSInteger, MITToursSelfGuidedTour) {
    MITToursSelfGuidedTourMap,
    MITToursSelfGuidedTourList
};

@interface MITToursSelfGuidedTourContainerController () <MITToursSelfGuidedTourListViewControllerDelegate, MITToursMapViewControllerDelegate>

@property (nonatomic, strong) MITToursMapViewController *mapViewController;
@property (nonatomic, strong) MITToursSelfGuidedTourListViewController *listViewController;

@property (nonatomic, strong) UISegmentedControl *mapListSegmentedControl;
@property (nonatomic, strong) UIBarButtonItem *userLocationBarButtonItem;

@end

@implementation MITToursSelfGuidedTourContainerController

- (instancetype)initWithTour:(MITToursTour *)tour
{
    self = [super init];
    if (self) {
        self.selfGuidedTour = tour;
    }
    return self;
}

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
    self.mapViewController.delegate = self;
    
    self.listViewController.view.frame =
    self.mapViewController.view.frame = self.view.bounds;
    
    [self addChildViewController:self.listViewController];
    [self addChildViewController:self.mapViewController];
    
    [self.view addSubview:self.listViewController.view];
    [self.view addSubview:self.mapViewController.view];
    
    NSDictionary *viewDict = @{ @"listView": self.listViewController.view,
                                @"mapView": self.mapViewController.view,
                                @"topGuide": self.topLayoutGuide,
                                @"bottomGuide": self.bottomLayoutGuide };
    // TODO: Clean up the magic numbers here
    self.listViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.mapViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[mapView]-0-|" options:0 metrics:nil views:viewDict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topGuide]-0-[mapView]-0-[bottomGuide]" options:0 metrics:nil views:viewDict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[listView]-0-|" options:0 metrics:nil views:viewDict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[listView]-0-|" options:0 metrics:nil views:viewDict]];
    
    [self.listViewController.view setNeedsUpdateConstraints];
    [self.mapViewController.view setNeedsUpdateConstraints];
    [self.view setNeedsUpdateConstraints];
    [self.view layoutIfNeeded];
}

- (void)setupNavBar
{
    // Following screens should have no "Back" text on back button
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backItem;
    
    self.navigationController.navigationBar.translucent = NO;
}

- (void)setupToolbar
{
    self.navigationController.toolbar.translucent = NO;
    
    self.mapListSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Map", @"List"]];
    [self.mapListSegmentedControl addTarget:self action:@selector(showSelectedViewController) forControlEvents:UIControlEventValueChanged];
    [self.mapListSegmentedControl setWidth:90.0 forSegmentAtIndex:0];
    [self.mapListSegmentedControl setWidth:90.0 forSegmentAtIndex:1];
    
    [self.mapListSegmentedControl setSelectedSegmentIndex:0];
    
    UIBarButtonItem *segmentedControlItem = [[UIBarButtonItem alloc] initWithCustomView:self.mapListSegmentedControl];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
   
    self.userLocationBarButtonItem = self.mapViewController.tiledMapView.userLocationButton;
    
    self.toolbarItems = @[flexibleSpace, segmentedControlItem, flexibleSpace, self.userLocationBarButtonItem];
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

- (void)selfGuidedTourListViewControllerDidPressInfoButton:(MITToursSelfGuidedTourListViewController *)selfGuidedTourListViewController
{
    [self transitionToTourInfo];
}

#pragma mark - Current Location Button

- (void)showCurrentLocationButton
{
    NSMutableArray *items = [self.toolbarItems mutableCopy];
    if (![items containsObject:self.userLocationBarButtonItem]) {
        [items addObject:self.userLocationBarButtonItem];
        [self setToolbarItems:items animated:YES];
    }
}

- (void)hideCurrentLocationButton
{
    NSMutableArray *items = [self.toolbarItems mutableCopy];
    if ([items containsObject:self.userLocationBarButtonItem]) {
        [items removeObject:self.userLocationBarButtonItem];
        [self setToolbarItems:items animated:YES];
    }
}

#pragma mark - MITToursSelfGuidedTourListViewControllerDelegate Methods

- (void)selfGuidedTourListViewController:(MITToursSelfGuidedTourListViewController *)selfGuidedTourListViewController didSelectStop:(MITToursStop *)stop
{
    [self transitionToDetailsForStop:stop];
}

#pragma mark - MITToursMapViewControllerDelegate Methods

- (void)mapViewController:(MITToursMapViewController *)mapViewController didSelectCalloutForStop:(MITToursStop *)stop
{
    [self transitionToDetailsForStop:stop];
}

- (void)mapViewControllerDidPressInfoButton:(MITToursMapViewController *)mapViewController
{
    [self transitionToTourInfo];
}

#pragma mark - Transition to Stop Details

- (void)transitionToDetailsForStop:(MITToursStop *)stop
{
    [self.mapViewController saveCurrentMapRect];
    MITToursStopDetailContainerViewController *stopDetailContainerViewController = [[MITToursStopDetailContainerViewController alloc] initWithTour:self.selfGuidedTour stop:stop nibName:nil bundle:nil];
    [self.navigationController pushViewController:stopDetailContainerViewController animated:YES];
}

#pragma mark - Transition to Tour Info

- (void)transitionToTourInfo
{
    [self.mapViewController saveCurrentMapRect];
    MITToursTourDetailsViewController *infoVC = [[MITToursTourDetailsViewController alloc] init];
    infoVC.tour = self.selfGuidedTour;
    [self.navigationController pushViewController:infoVC animated:YES];
}

@end
