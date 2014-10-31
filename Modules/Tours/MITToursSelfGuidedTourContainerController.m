#import "MITToursSelfGuidedTourContainerController.h"
#import "MITToursSelfGuidedTourListViewController.h"
#import "MITToursSelfGuidedTourInfoViewController.h"
#import "MITToursMapViewController.h"

typedef NS_ENUM(NSInteger, MITToursSelfGuidedTour) {
    MITToursSelfGuidedTourMap,
    MITToursSelfGuidedTourList
};

@interface MITToursSelfGuidedTourContainerController ()

@property (nonatomic, strong) UIViewController *mapViewController;
@property (nonatomic, strong) MITToursSelfGuidedTourListViewController *listViewController;

@property (nonatomic, strong) UISegmentedControl *mapListSegmentedControl;

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

- (void)setupViewControllers
{
    self.listViewController = [[MITToursSelfGuidedTourListViewController alloc] init];
    self.listViewController.tour = self.selfGuidedTour;

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
}

- (void)setupToolbar
{
    self.mapListSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Map", @"List"]];
    [self.mapListSegmentedControl addTarget:self action:@selector(showSelectedViewController) forControlEvents:UIControlEventValueChanged];
    [self.mapListSegmentedControl setWidth:90.0 forSegmentAtIndex:0];
    [self.mapListSegmentedControl setWidth:90.0 forSegmentAtIndex:1];
    
    [self.mapListSegmentedControl setSelectedSegmentIndex:0];
    
    UIBarButtonItem *segmentedControlItem = [[UIBarButtonItem alloc] initWithCustomView:self.mapListSegmentedControl];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[flexibleSpace, segmentedControlItem, flexibleSpace];
    [self.navigationController setToolbarHidden:NO];
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
}

- (void)showListViewController
{
    self.mapViewController.view.hidden = YES;
    self.listViewController.view.hidden = NO;
}

- (void)infoButtonPressed:(id)sender
{
    MITToursSelfGuidedTourInfoViewController *infoVC = [[MITToursSelfGuidedTourInfoViewController alloc] init];
    infoVC.tour = self.selfGuidedTour;
    [self.navigationController pushViewController:infoVC animated:YES];
}

@end
