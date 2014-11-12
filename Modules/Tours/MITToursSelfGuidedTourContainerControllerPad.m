#import "MITToursSelfGuidedTourContainerControllerPad.h"
#import "MITToursSelfGuidedTourListViewController.h"
#import "MITToursSelfGuidedTourInfoViewController.h"
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
    self.mapViewController.shouldShowStopDescriptions = YES;
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
    UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithTitle:@"Info" style:UIBarButtonItemStylePlain target:self action:@selector(infoButtonPressed:)];
    self.navigationItem.rightBarButtonItem = infoButton;
    
    // Following screens should have no "Back" text on back button
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backItem;
}

- (void)setupToolbar
{
    // We use actual UIButtons so that we can easily change the selected state
    // TODO: Drop in the correct assets here
    UIImage *listToggleImageNormal = [UIImage imageNamed:@"global/menu"];
    UIImage *listToggleImageSelected = [UIImage imageNamed:@"global/menu"];
    CGSize listToggleImageSize = listToggleImageNormal.size;
    self.listViewToggleButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, listToggleImageSize.width, listToggleImageSize.height)];
    [self.listViewToggleButton setImage:listToggleImageNormal forState:UIControlStateNormal];
    [self.listViewToggleButton setImage:listToggleImageSelected forState:UIControlStateSelected];
    [self.listViewToggleButton addTarget:self action:@selector(listButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *listButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.listViewToggleButton];
    
    UIImage *userLocationImageNormal = [UIImage imageNamed:@"map/map_location"];
    UIImage *userLocationImageSelected = [UIImage imageNamed:@"map/map_location_selected"];
    CGSize userLocationImageSize = userLocationImageNormal.size;
    self.userLocationButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, userLocationImageSize.width, userLocationImageSize.height)];
    [self.userLocationButton setImage:userLocationImageNormal forState:UIControlStateNormal];
    [self.userLocationButton setImage:userLocationImageSelected forState:UIControlStateSelected];
    [self.userLocationButton addTarget:self action:@selector(currentLocationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *currentLocationButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.userLocationButton];

    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[listButtonItem, flexibleSpace, currentLocationButtonItem];
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
    if (animated) {
        [UIView animateWithDuration:kPanelAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.listViewLeadingConstraint.constant = offset;
            [self.view setNeedsUpdateConstraints];
            [self.view layoutIfNeeded];
        } completion:nil];
    } else {
        self.listViewLeadingConstraint.constant = offset;
        [self.view setNeedsUpdateConstraints];
        [self.view layoutIfNeeded];
    }
}

#pragma mark - Actions

- (void)infoButtonPressed:(UIBarButtonItem *)sender
{
    
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
    MITToursStopDetailContainerViewController *detailViewController = [[MITToursStopDetailContainerViewController alloc] initWithTour:self.selfGuidedTour stop:stop nibName:nil bundle:nil];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

- (void)mapViewController:(MITToursMapViewController *)mapViewController didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    self.userLocationButton.selected = (mode == MKUserTrackingModeFollow);
}

@end
