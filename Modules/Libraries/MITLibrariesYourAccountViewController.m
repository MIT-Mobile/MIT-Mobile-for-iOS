#import "MITLibrariesYourAccountViewController.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesUser.h"

#import "MITLibrariesLoansViewController.h"
#import "MITLibrariesHoldsViewController.h"
#import "MITLibrariesFinesViewController.h"

typedef NS_ENUM(NSInteger, MITLibrariesYourAccountSection) {
    MITLibrariesYourAccountSectionLoans = 0,
    MITLibrariesYourAccountSectionFines,
    MITLibrariesYourAccountSectionHolds
};

@interface MITLibrariesYourAccountViewController () <MITLibrariesUserRefreshDelegate>

@property (nonatomic, strong) UISegmentedControl *loansHoldsFinesSegmentedControl;

@property (nonatomic, strong) MITLibrariesLoansViewController *loansViewController;
@property (nonatomic, strong) MITLibrariesHoldsViewController *holdsViewController;
@property (nonatomic, strong) MITLibrariesFinesViewController *finesViewController;

@property (nonatomic, strong) MITLibrariesUser *user;
@property (nonatomic, assign) NSDate *finesUpdatedDate;

@end

@implementation MITLibrariesYourAccountViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"My Account";
    
    [self setupViewControllers];
    
    [self refreshUserData];
    
    [self setupToolbar];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidBecomeActive
{
    [self refreshUserData];
}

- (void)refreshUserData
{
    [MITLibrariesWebservices getUserWithCompletion:^(MITLibrariesUser *user, NSError *error) {
        if (!error) {
            self.user = user;
            self.finesUpdatedDate = [NSDate date];
            [self refreshViewControllers];
        }
        else {
            [self.navigationController popViewControllerAnimated:NO];
        }
    }];
}

- (void)setupToolbar
{
    self.loansHoldsFinesSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Loans", @"Fines", @"Holds"]];
    [self.loansHoldsFinesSegmentedControl addTarget:self action:@selector(showSelectedViewController) forControlEvents:UIControlEventValueChanged];
    [self.loansHoldsFinesSegmentedControl setWidth:90.0 forSegmentAtIndex:0];
    [self.loansHoldsFinesSegmentedControl setWidth:90.0 forSegmentAtIndex:1];
    [self.loansHoldsFinesSegmentedControl setWidth:90.0 forSegmentAtIndex:2];
    
    [self.loansHoldsFinesSegmentedControl setSelectedSegmentIndex:0];
    
    UIBarButtonItem *segmentedControlItem = [[UIBarButtonItem alloc] initWithCustomView:self.loansHoldsFinesSegmentedControl];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[flexibleSpace, segmentedControlItem, flexibleSpace];
    [self.navigationController setToolbarHidden:NO];
}

- (void)setupViewControllers
{
    self.loansViewController = [[MITLibrariesLoansViewController alloc] init];
    self.holdsViewController = [[MITLibrariesHoldsViewController alloc] init];
    self.finesViewController = [[MITLibrariesFinesViewController alloc] init];
    
    self.loansViewController.refreshDelegate =
    self.holdsViewController.refreshDelegate =
    self.finesViewController.refreshDelegate = self;
    
    self.loansViewController.view.frame =
    self.holdsViewController.view.frame =
    self.finesViewController.view.frame = self.view.bounds;
    
    [self addChildViewController:self.loansViewController];
    [self addChildViewController:self.holdsViewController];
    [self addChildViewController:self.finesViewController];
    
    [self.view addSubview:self.finesViewController.view];
    [self.view addSubview:self.holdsViewController.view];
    [self.view addSubview:self.loansViewController.view];
}

- (void)showSelectedViewController
{
    switch (self.loansHoldsFinesSegmentedControl.selectedSegmentIndex) {
        case MITLibrariesYourAccountSectionLoans:
            [self showLoansViewController];
            break;
        case MITLibrariesYourAccountSectionFines:
            [self showFinesViewController];
            break;
        case MITLibrariesYourAccountSectionHolds:
            [self showHoldsViewController];
            break;
        default:
            break;
    }
}

- (void)showLoansViewController
{
    self.holdsViewController.view.hidden =
    self.finesViewController.view.hidden = YES;
    
    self.title = self.loansViewController.title;
    self.loansViewController.view.hidden = NO;
}

- (void)showHoldsViewController
{
    self.loansViewController.view.hidden =
    self.finesViewController.view.hidden = YES;
    
    self.title = self.holdsViewController.title;
    self.holdsViewController.view.hidden = NO;
}

- (void)showFinesViewController
{
    self.holdsViewController.view.hidden =
    self.loansViewController.view.hidden = YES;
    
    self.title = self.finesViewController.title;
    self.finesViewController.view.hidden = NO;
}

- (void)refreshViewControllers
{
    self.loansViewController.overdueItemsCount = self.user.overdueItemsCount;
    self.loansViewController.items = self.user.loans;
    
    self.holdsViewController.readyForPickupCount = self.user.readyForPickupCount;
    self.holdsViewController.items = self.user.holds;
    
    self.finesViewController.finesUpdatedDate = self.finesUpdatedDate;
    self.finesViewController.finesBalance = self.user.formattedBalance;
    self.finesViewController.items = self.user.fines;
    
    [self showSelectedViewController];
}

@end
