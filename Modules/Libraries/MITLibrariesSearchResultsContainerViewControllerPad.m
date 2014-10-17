#import "MITLibrariesSearchResultsContainerViewControllerPad.h"
#import "MITLibrariesSearchController.h"
#import "MITLibrariesSearchResultsViewController.h"

@interface MITLibrariesSearchResultsContainerViewControllerPad ()

@property (nonatomic, strong) MITLibrariesSearchController *searchController;
@property (nonatomic, strong) MITLibrariesSearchResultsViewController *listViewController;

// TODO: Replace this with an actual collection view VC
@property (nonatomic, strong) UIViewController *gridViewController;

@end

@implementation MITLibrariesSearchResultsContainerViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupViewControllers];
}

- (void)setupSearchController
{
    self.searchController = [[MITLibrariesSearchController alloc] init];
}

- (void)setupViewControllers
{
    self.listViewController = [[MITLibrariesSearchResultsViewController alloc] init];
    
    self.listViewController.searchController = self.searchController;
    
    self.listViewController.view.frame = self.view.bounds;
    
    [self addChildViewController:self.listViewController];
    
    [self.view addSubview:self.listViewController.view];
}

- (void)setSearchTerm:(NSString *)searchTerm
{
    _searchTerm = searchTerm;
 
    [self.listViewController search:searchTerm];
}

@end
