#import "MITToursSelfGuidedTourContainerController.h"
#import "MITToursSelfGuidedTourListViewController.h"

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
    
    [self setupToolbar];
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

- (void)setupViewControllers
{
    self.listViewController = [[MITToursSelfGuidedTourListViewController alloc] init];
    self.mapViewController = [[UIViewController alloc] init];
    self.mapViewController.view.backgroundColor = [UIColor blueColor];

    self.listViewController.view.frame =
    self.mapViewController.view.frame = self.view.bounds;
    
    [self addChildViewController:self.listViewController];
    [self addChildViewController:self.mapViewController];
    
    [self.view addSubview:self.listViewController.view];
    [self.view addSubview:self.mapViewController.view];
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

@end
