#import "MITLibrariesHomeViewControllerPad.h"
#import "MITLibrariesYourAccountViewControllerPad.h"
#import "MITLibrariesLocationsHoursViewController.h"
#import "MITLibrariesLibraryDetailViewController.h"
#import "MITLibrariesLibrary.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesQuickLinksViewController.h"

typedef NS_ENUM(NSInteger, MITLibrariesLayoutMode) {
    MITLibrariesLayoutModeList,
    MITLibrariesLayoutModeGrid
};

@interface MITLibrariesHomeViewControllerPad () <MITLibrariesLocationsIPadDelegate, UISearchBarDelegate>

@property (nonatomic, strong) MITLibrariesYourAccountViewControllerPad *accountViewController;

@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic, strong) UIBarButtonItem *locationsAndHoursButton;
@property (nonatomic, strong) UIBarButtonItem *askUsTellUsButton;
@property (nonatomic, strong) UIBarButtonItem *quickLinksButton;

@property (nonatomic, strong) NSArray *links;

@property (nonatomic, strong) UIPopoverController *locationsAndHoursPopoverController;
@property (nonatomic, strong) UIPopoverController *quickLinksPopoverController;

@property (nonatomic, strong) MITLibrariesQuickLinksViewController *quickLinksViewController;

@property (nonatomic) MITLibrariesLayoutMode layoutMode;
@property (nonatomic, strong) UIBarButtonItem *gridLayoutButton;
@property (nonatomic, strong) UIBarButtonItem *listLayoutButton;

@end

@implementation MITLibrariesHomeViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;

    [self setupViewControllers];

    [self setupNavBar];
    [self setupToolbar];
    [self loadLinks];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupNavBar
{
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(-10, 0, 340, 44)];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.searchBar.placeholder = @"Search MIT's WorldCat";
        
    UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    searchBarView.autoresizingMask = UIViewAutoresizingNone;
    self.searchBar.delegate = self;
    [searchBarView addSubview:self.searchBar];
    self.navigationItem.titleView = searchBarView;
    
    
    self.listLayoutButton = [[UIBarButtonItem alloc] initWithTitle:@"List" style:UIBarButtonItemStylePlain target:self action:@selector(listViewPressed)];
    self.gridLayoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Grid" style:UIBarButtonItemStylePlain target:self action:@selector(gridViewPressed)];
    self.layoutMode = MITLibrariesLayoutModeList;
}

- (void)setupToolbar
{
    self.navigationController.toolbar.translucent = NO;
    self.locationsAndHoursButton = [[UIBarButtonItem alloc] initWithTitle:@"Locations & Hours" style:UIBarButtonItemStylePlain target:self action:@selector(locationsAndHoursPressed:)];
    self.askUsTellUsButton = [[UIBarButtonItem alloc] initWithTitle:@"Ask Us/Tell Us" style:UIBarButtonItemStylePlain target:self action:@selector(askUsTellUsPressed:)];
    self.quickLinksButton = [[UIBarButtonItem alloc] initWithTitle:@"Quick Links" style:UIBarButtonItemStylePlain target:self action:@selector(quickLinksPressed:)];
    
    CGSize locationsSize = [self.locationsAndHoursButton.title sizeWithAttributes:[self.locationsAndHoursButton titleTextAttributesForState:UIControlStateNormal]];
    CGSize quickLinksSize = [self.quickLinksButton.title sizeWithAttributes:[self.quickLinksButton titleTextAttributesForState:UIControlStateNormal]];
    
    UIBarButtonItem *evenPaddingButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    evenPaddingButton.width = locationsSize.width - quickLinksSize.width;
    
    self.toolbarItems = @[self.locationsAndHoursButton,
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          self.askUsTellUsButton,
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          evenPaddingButton,
                          self.quickLinksButton];
}

- (void)loadLinks
{
    [MITLibrariesWebservices getLinksWithCompletion:^(NSArray *links, NSError *error) {
        if (links) {
            self.links = links;
        }
    }];
}

- (void)locationsAndHoursPressed:(id)sender
{
    MITLibrariesLocationsHoursViewController *vc = [[MITLibrariesLocationsHoursViewController alloc] init];
    vc.delegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    
    self.locationsAndHoursPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    [self.locationsAndHoursPopoverController setPopoverContentSize:CGSizeMake(320, 568)];
    [self.locationsAndHoursPopoverController presentPopoverFromBarButtonItem:self.locationsAndHoursButton permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

- (void)showLibraryDetailForLibrary:(MITLibrariesLibrary *)library
{
    MITLibrariesLibraryDetailViewController *detailVC = [[MITLibrariesLibraryDetailViewController alloc] init];
    detailVC.library = library;
    detailVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:detailVC action:@selector(dismiss)];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:detailVC];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self.locationsAndHoursPopoverController dismissPopoverAnimated:YES];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)askUsTellUsPressed:(id)sender
{
    NSLog(@"Ask Us");
}

- (void)quickLinksPressed:(id)sender
{
    [self.quickLinksPopoverController presentPopoverFromBarButtonItem:self.quickLinksButton permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

- (void)setupViewControllers
{
    self.accountViewController = [[MITLibrariesYourAccountViewControllerPad alloc] init];
    self.accountViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.accountViewController.view.frame = self.view.bounds;
    
    [self addChildViewController:self.accountViewController];
    
    [self.view addSubview:self.accountViewController.view];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[accountView]-0-|" options:0 metrics:nil views:@{@"accountView": self.accountViewController.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[accountView]-0-|" options:0 metrics:nil views:@{@"accountView": self.accountViewController.view}]];
    
    [self setupQuickLinksPopover];
}

- (void)setupQuickLinksPopover
{
    self.quickLinksViewController = [[MITLibrariesQuickLinksViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.quickLinksViewController];
    
    self.quickLinksPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    [self.quickLinksPopoverController setPopoverContentSize:CGSizeMake(320, 132 + navController.navigationBar.frame.size.height)];
}

- (void)setLinks:(NSArray *)links
{
    _links = links;
    if (self.quickLinksViewController) {
        self.quickLinksViewController.links = links;
    }
}

- (void)setLayoutMode:(MITLibrariesLayoutMode)layoutMode
{
    _layoutMode = layoutMode;
    
    if (layoutMode == MITLibrariesLayoutModeList) {
        self.navigationItem.rightBarButtonItem = self.gridLayoutButton;
    }
    else {
        self.navigationItem.rightBarButtonItem = self.listLayoutButton;
    }
    
    // TODO: Swap view controllers
}

- (void)listViewPressed
{
    self.layoutMode = MITLibrariesLayoutModeList;
}

- (void)gridViewPressed
{
    self.layoutMode = MITLibrariesLayoutModeGrid;
}

@end
