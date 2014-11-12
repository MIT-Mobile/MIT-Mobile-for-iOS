#import "MITToursSelfGuidedTourContainerController.h"
#import "MITToursSelfGuidedTourListViewController.h"
#import "MITToursSelfGuidedTourInfoViewController.h"
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
@property (nonatomic, strong) UIButton *userLocationButton;

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
}

- (void)setupToolbar
{
    self.mapListSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Map", @"List"]];
    [self.mapListSegmentedControl addTarget:self action:@selector(showSelectedViewController) forControlEvents:UIControlEventValueChanged];
    [self.mapListSegmentedControl setWidth:90.0 forSegmentAtIndex:0];
    [self.mapListSegmentedControl setWidth:90.0 forSegmentAtIndex:1];
    
    [self.mapListSegmentedControl setSelectedSegmentIndex:0];
    
    UIBarButtonItem *segmentedControlItem = [[UIBarButtonItem alloc] initWithCustomView:self.mapListSegmentedControl];
    
    // For user location button, we use an actual UIButton so that we can easily change its selected state
    UIImage *userLocationImageNormal = [UIImage imageNamed:@"map/map_location"];
    UIImage *userLocationImageSelected = [UIImage imageNamed:@"map/map_location_selected"];
    CGSize imageSize = userLocationImageNormal.size;
    self.userLocationButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, imageSize.width, imageSize.height)];
    [self.userLocationButton setImage:userLocationImageNormal forState:UIControlStateNormal];
    [self.userLocationButton setImage:userLocationImageSelected forState:UIControlStateSelected];
    [self.userLocationButton addTarget:self action:@selector(currentLocationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *currentLocationButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.userLocationButton];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[currentLocationButtonItem, flexibleSpace, segmentedControlItem, flexibleSpace];

    self.userLocationBarButtonItem = currentLocationButtonItem;
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
    MITToursSelfGuidedTourInfoViewController *infoVC = [[MITToursSelfGuidedTourInfoViewController alloc] init];
    infoVC.tour = self.selfGuidedTour;
    [self.navigationController pushViewController:infoVC animated:YES];
}

#pragma mark - Current Location Button

- (void)showCurrentLocationButton
{
    NSMutableArray *items = [self.toolbarItems mutableCopy];
    if (![items containsObject:self.userLocationBarButtonItem]) {
        [items insertObject:self.userLocationBarButtonItem atIndex:0];
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

- (void)currentLocationButtonPressed:(id)sender
{
    [self.mapViewController toggleUserTrackingMode];
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

- (void)mapViewController:(MITToursMapViewController *)mapViewController didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    self.userLocationButton.selected = (mode == MKUserTrackingModeFollow);
}

#pragma mark - Transition to Stop Details

- (void)transitionToDetailsForStop:(MITToursStop *)stop
{
    MITToursStopDetailContainerViewController *stopDetailContainerViewController = [[MITToursStopDetailContainerViewController alloc] initWithTour:self.selfGuidedTour stop:stop nibName:nil bundle:nil];
    [self.navigationController pushViewController:stopDetailContainerViewController animated:YES];
}

@end
