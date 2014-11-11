#import "MITToursSelfGuidedTourContainerControllerPad.h"
#import "MITToursSelfGuidedTourListViewController.h"
#import "MITToursSelfGuidedTourInfoViewController.h"
#import "MITToursMapViewController.h"

@interface MITToursSelfGuidedTourContainerControllerPad ()

@property (nonatomic, strong) MITToursMapViewController *mapViewController;
@property (nonatomic, strong) MITToursSelfGuidedTourListViewController *listViewController;

@property (nonatomic, strong) NSLayoutConstraint *listViewLeadingConstraint;

@property (nonatomic) BOOL isShowingListView;

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
    
    self.mapViewController = [[MITToursMapViewController alloc] initWithTour:self.selfGuidedTour nibName:nil bundle:nil];
    
    [self addChildViewController:self.listViewController];
    [self addChildViewController:self.mapViewController];

    [self.view addSubview:self.mapViewController.view];
    [self.view addSubview:self.listViewController.view];
    
    NSDictionary *viewDict = @{ @"listView": self.listViewController.view,
                                @"mapView": self.mapViewController.view };
    // TODO: Clean up the magic numbers here
    self.listViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.mapViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[mapView]-0-|" options:0 metrics:nil views:viewDict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[mapView]-0-|" options:0 metrics:nil views:viewDict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-64-[listView]-44-|" options:0 metrics:nil views:viewDict]];
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
    UIBarButtonItem *listButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"global/menu"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(listButtonPressed:)];
    UIBarButtonItem *currentLocationButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map/map_location"]
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(currentLocationButtonPressed:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[listButton, flexibleSpace, currentLocationButtonItem];
}

#pragma mark - List View Panel

- (void)showListViewAnimated:(BOOL)animated
{
    if (self.isShowingListView) {
        return;
    }
    self.isShowingListView = YES;
    [self moveListViewToOffset:0 animated:animated];
}

- (void)hideListViewAnimated:(BOOL)animated
{
    if (!self.isShowingListView) {
        return;
    }
    self.isShowingListView = NO;
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
    
}

@end
