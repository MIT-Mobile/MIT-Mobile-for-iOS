#import "MITToursSelfGuidedTourContainerControllerPad.h"
#import "MITToursSelfGuidedTourListViewController.h"
#import "MITToursTourDetailsViewController.h"
#import "MITToursMapViewController.h"
#import "MITToursStopDetailContainerViewController.h"

@interface MITToursSelfGuidedTourContainerControllerPad () <MITToursSelfGuidedTourListViewControllerDelegate, MITToursMapViewControllerDelegate>

@property (nonatomic, strong) MITToursMapViewController *mapViewController;
@property (nonatomic, strong) MITToursSelfGuidedTourListViewController *listViewController;

@property (nonatomic, strong) NSLayoutConstraint *listViewLeadingConstraint;
@property (nonatomic) BOOL isShowingListView;

@property (nonatomic, strong) UIButton *userLocationButton;
@property (nonatomic, strong) UIButton *listViewToggleButton;

@end

static NSTimeInterval const kPanelAnimationDuration = 0.5;

@implementation MITToursSelfGuidedTourContainerControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Self-Guided Tour";
    
    [self setupViewControllers];
    [self setupNavBar];
    [self setupToolbar];
}

- (void)setupViewControllers
{
    self.listViewController = [[MITToursSelfGuidedTourListViewController alloc] init];
    self.listViewController.tour = self.selfGuidedTour;
    self.listViewController.delegate = self;
    
    self.mapViewController = [[MITToursMapViewController alloc] initWithTour:self.selfGuidedTour nibName:nil bundle:nil];
    self.mapViewController.shouldShowTourDetailsPanel = NO;
    self.mapViewController.delegate = self;
    
    [self addChildViewController:self.listViewController];
    [self addChildViewController:self.mapViewController];

    [self.view addSubview:self.mapViewController.view];
    [self.view addSubview:self.listViewController.view];
    
    NSDictionary *viewDict = @{ @"listView": self.listViewController.view,
                                @"mapView": self.mapViewController.view,
                                @"topGuide": self.topLayoutGuide,
                                @"bottomGuide": self.bottomLayoutGuide };
    // TODO: Clean up the magic numbers here
    self.listViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.mapViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[listView]-0-[mapView]-0-|" options:0 metrics:nil views:viewDict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topGuide]-0-[mapView]-0-[bottomGuide]" options:0 metrics:nil views:viewDict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topGuide]-0-[listView]-0-[bottomGuide]" options:0 metrics:nil views:viewDict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[listView(==320)]" options:0 metrics:nil views:viewDict]];

    // We keep track of the list view's leading constraint so we can use it to show/hide the list
    self.listViewLeadingConstraint = [NSLayoutConstraint constraintWithItem:self.listViewController.view
                                                                  attribute:NSLayoutAttributeLeading
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeLeading
                                                                 multiplier:1
                                                                   constant:0];
    [self.view addConstraint:self.listViewLeadingConstraint];

    [self.listViewController.view setNeedsUpdateConstraints];
    [self.mapViewController.view setNeedsUpdateConstraints];
    [self.view setNeedsUpdateConstraints];
    [self.view layoutIfNeeded];
    
    [self showListViewAnimated:NO];
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
    [self.navigationController setToolbarHidden:NO];
    
    // We use actual UIButtons so that we can easily change the selected state
    UIImage *listToggleImageNormal = [UIImage imageNamed:@"tours/list-view"];
    UIImage *listToggleImageSelected = [UIImage imageNamed:@"tours/list-view"];
    CGSize listToggleImageSize = listToggleImageNormal.size;
    self.listViewToggleButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, listToggleImageSize.width, listToggleImageSize.height)];
    [self.listViewToggleButton setImage:listToggleImageNormal forState:UIControlStateNormal];
    [self.listViewToggleButton setImage:listToggleImageSelected forState:UIControlStateSelected];
    [self.listViewToggleButton addTarget:self action:@selector(listButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *listButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.listViewToggleButton];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[listButtonItem, flexibleSpace, self.mapViewController.tiledMapView.userLocationButton];
}

#pragma mark - List View Panel

- (void)showListViewAnimated:(BOOL)animated
{
    if (self.isShowingListView) {
        return;
    }
    self.isShowingListView = YES;
    self.listViewToggleButton.selected = YES;
    [self moveListViewToOffset:0 animated:animated];
}

- (void)hideListViewAnimated:(BOOL)animated
{
    if (!self.isShowingListView) {
        return;
    }
    self.isShowingListView = NO;
    self.listViewToggleButton.selected = NO;
    [self moveListViewToOffset:-CGRectGetWidth(self.listViewController.view.frame) animated:animated];
}

- (void)moveListViewToOffset:(CGFloat)offset animated:(BOOL)animated
{
    self.listViewLeadingConstraint.constant = offset;
    if (animated) {
        [UIView animateWithDuration:kPanelAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self.view layoutIfNeeded];
        } completion:nil];
    } else {
        [self.view layoutIfNeeded];
    }
}

#pragma mark - Actions

- (void)selfGuidedTourListViewControllerDidPressInfoButton:(MITToursSelfGuidedTourListViewController *)selfGuidedTourListViewController
{
    MITToursTourDetailsViewController *infoVC = [[MITToursTourDetailsViewController alloc] init];
    infoVC.tour = self.selfGuidedTour;
    infoVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(tourInfoDoneButtonWasPressed:)];
    
    UINavigationController *infoNavigationController = [[UINavigationController alloc] initWithRootViewController:infoVC];
    infoNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentViewController:infoNavigationController animated:YES completion:nil];
}

- (void)tourInfoDoneButtonWasPressed:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)listButtonPressed:(UIBarButtonItem *)sender
{
    if (self.isShowingListView) {
        [self hideListViewAnimated:YES];
    } else {
        [self showListViewAnimated:YES];
    }
}

- (void)currentLocationButtonPressed:(UIBarButtonItem *)sender
{
    [self.mapViewController toggleUserTrackingMode];
}

#pragma mark - MITToursSelfGuidedTourListViewController Methods

- (void)selfGuidedTourListViewController:(MITToursSelfGuidedTourListViewController *)selfGuidedTourListViewController didSelectStop:(MITToursStop *)stop
{
    [self.mapViewController selectStop:stop];
}

#pragma mark - MITToursMapViewControllerDelegate Methods

- (void)mapViewController:(MITToursMapViewController *)mapViewController didSelectStop:(MITToursStop *)stop
{
    [self.listViewController selectStop:stop];
}

- (void)mapViewController:(MITToursMapViewController *)mapViewController didDeselectStop:(MITToursStop *)stop
{
    [self.listViewController deselectStop:stop];
}

- (void)mapViewController:(MITToursMapViewController *)mapViewController didSelectCalloutForStop:(MITToursStop *)stop
{
    [self.mapViewController saveCurrentMapRect];
    MITToursStopDetailContainerViewController *detailViewController = [[MITToursStopDetailContainerViewController alloc] initWithTour:self.selfGuidedTour stop:stop nibName:nil bundle:nil];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

- (void)mapViewController:(MITToursMapViewController *)mapViewController didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    self.userLocationButton.selected = (mode == MKUserTrackingModeFollow);
}

@end
