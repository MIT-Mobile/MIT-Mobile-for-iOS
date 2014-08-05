//
//  MITEventsRootViewController.m
//  MIT Mobile
//
//  Created by Logan Wright on 8/5/14.
//
//

#import "MITEventsRootViewController.h"

#import "MITEventsHomeViewController.h"
#import "MITDateNavigationBarView.h"
#import "UIKit+MITAdditions.h"


@interface MITEventsRootViewController ()

@property (strong, nonatomic) UISplitViewController *splitViewController;
@property (strong, nonatomic) UINavigationController *masterNavigationController;
@property (strong, nonatomic) UINavigationController *detailNavigationController;

// Placeholder
@property (strong, nonatomic) UIViewController *mapsViewController;

@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIBarButtonItem *searchMagnifyingGlassBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *searchCancelBarButtonItem;

@property (strong, nonatomic) MITEventsHomeViewController *eventsHomeViewController;
@property (strong, nonatomic) MITDateNavigationBarView *dateNavigationBarView;
@end

@implementation MITEventsRootViewController

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
    // Do any additional setup after loading the view.
    
    self.title = @"MIT Events";
    [self setupViewControllers];
    [self setupRightBarButtonItems];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self setupLeftBarButtonItems];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self alignDateNavigationBar];
}

- (void)alignDateNavigationBar
{
    UIView *customView = [[self.navigationItem.leftBarButtonItems lastObject] customView];
    CGRect currentRect = [self.view convertRect:customView.frame fromView:customView.superview];
    self.dateNavigationBarView.bounds = CGRectMake(0, 0, 320 - currentRect.origin.x, currentRect.size.height);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - BarButtonItems Setup

- (void) setupLeftBarButtonItems
{
    [self setupDateNavigationBar];
    
    UIBarButtonItem *dateNavBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.dateNavigationBarView];
    NSMutableArray *currentItems = [NSMutableArray array];
    [currentItems addObject:self.navigationItem.leftBarButtonItems.firstObject];
    [currentItems addObject:dateNavBarButtonItem];
    self.navigationItem.leftBarButtonItems = currentItems;
}

- (void)setupDateNavigationBar
{
    UINib *nib = [UINib nibWithNibName:@"MITDateNavigationBarView" bundle:nil];
    self.dateNavigationBarView = [[nib instantiateWithOwner:self options:nil] objectAtIndex:0];
    [self.dateNavigationBarView.hamburgerButton addTarget:self.navigationItem.leftBarButtonItem.target action:self.navigationItem.leftBarButtonItem.action forControlEvents:UIControlEventTouchUpInside];
    self.dateNavigationBarView.bounds = CGRectMake(0, 0, 320, 44);
    self.dateNavigationBarView.currentDateLabel.text = @"Thursday, Feb 20, 2014";
    self.dateNavigationBarView.tintColor = [UIColor mit_tintColor];
    [self setupDateNavigationButtonPresses];
    
}

- (void) setupDateNavigationButtonPresses
{
    [self.dateNavigationBarView.previousDateButton addTarget:self action:@selector(previousDayButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.dateNavigationBarView.nextDateButton addTarget:self action:@selector(nextDayButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.dateNavigationBarView.showDateControlButton addTarget:self action:@selector(showDatePickerButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupRightBarButtonItems {
    
    self.searchMagnifyingGlassBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"global/search"]
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(searchButtonPressed:)];
     self.navigationItem.rightBarButtonItem = self.searchMagnifyingGlassBarButtonItem;
    
}

- (void)showSearchBar {
    
    if (!self.searchBar) {
        self.searchBar = [[UISearchBar alloc] init];
        self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
        self.searchBar.bounds = CGRectMake(0, 0, 320, 44);
        self.searchBar.showsCancelButton = YES;
        [self.searchBar setShowsCancelButton:YES animated:YES];
        self.searchBar.placeholder = @"Search";
    }
    
    if (!self.searchCancelBarButtonItem) {
        self.searchCancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(searchButtonPressed:)];
    }
    
    UIBarButtonItem *searchBarAsBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.searchBar];
    self.navigationItem.rightBarButtonItems = @[self.searchCancelBarButtonItem, searchBarAsBarButtonItem];
    
    
    [self.searchBar becomeFirstResponder];
}

- (void)hideSearchBar {
    
    if (!self.searchMagnifyingGlassBarButtonItem) {
        UIImage *searchImage = [UIImage imageNamed:@"global/search"];
        self.searchMagnifyingGlassBarButtonItem = [[UIBarButtonItem alloc] initWithImage:searchImage
                                                                                   style:UIBarButtonItemStylePlain
                                                                                  target:self
                                                                                  action:@selector(searchButtonPressed:)];
    }
    self.navigationItem.rightBarButtonItems = @[self.searchMagnifyingGlassBarButtonItem];
}

#pragma mark - Button Presses


- (void)previousDayButtonPressed:(UIButton *)sender
{
    
}

- (void)nextDayButtonPressed:(UIButton *)sender
{
    
}

- (void)showDatePickerButtonPressed:(UIButton *)sender
{
    
}

- (void)searchButtonPressed:(UIBarButtonItem *)barButtonItem {
    if (barButtonItem == self.searchMagnifyingGlassBarButtonItem) {
        [self showSearchBar];
    }
    else if (barButtonItem == self.searchCancelBarButtonItem) {
        [self hideSearchBar];
    }
}

#pragma mark - ViewControllers Setup

- (void)setupViewControllers {
    [self setupEventsHomeViewController];
    [self setupMapViewController];
    [self setupSplitViewController];
}

- (void)setupEventsHomeViewController {
    self.eventsHomeViewController = [[MITEventsHomeViewController alloc] initWithNibName:nil bundle:nil];
    self.masterNavigationController = [[UINavigationController alloc] initWithRootViewController:self.eventsHomeViewController];
}

- (void)setupMapViewController {
    self.mapsViewController = [UIViewController new];
    self.mapsViewController.view.backgroundColor = [UIColor magentaColor];
    
    self.detailNavigationController = [[UINavigationController alloc] initWithRootViewController:self.mapsViewController];
}

- (void)setupSplitViewController {
    self.splitViewController = [[UISplitViewController alloc] init];
    self.splitViewController.viewControllers = @[self.eventsHomeViewController, self.mapsViewController];
    
    [self addChildViewController:self.splitViewController];
    self.splitViewController.view.frame = self.view.bounds;
    [self.view addSubview:self.splitViewController.view];
    [self.splitViewController didMoveToParentViewController:self];
}

@end
