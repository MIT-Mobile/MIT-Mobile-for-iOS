#import "MITMapBrowseContainerViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITMapCategoriesViewController.h"
#import "MITMapPlaceSelector.h"
#import "MITMapBookmarksViewController.h"
#import "MITMapTypeAheadTableViewController.h"
#import "MITMapModelController.h"

@interface MITMapBrowseContainerViewController ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) NSArray *viewControllers;
@property (weak, nonatomic) UIViewController *selectedViewController;

@end

@implementation MITMapBrowseContainerViewController

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setupViewControllers];
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setupToolbar];
    [self showViewControllerAtIndex:0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.selectedViewController beginAppearanceTransition:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.selectedViewController endAppearanceTransition];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.selectedViewController beginAppearanceTransition:NO animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.selectedViewController endAppearanceTransition];
}

#pragma mark - Toolbar Setup

- (void)setupToolbar
{
    [self setToolbarItems:@[[UIBarButtonItem flexibleSpace], [[UIBarButtonItem alloc] initWithCustomView:self.segmentedControl], [UIBarButtonItem flexibleSpace]] animated:NO];
}

#pragma mark - Child View Controller Management

- (void)setupViewControllers
{
    // TODO: add done bar button item to each view controller
    
    MITMapCategoriesViewController *categoriesViewController = [[MITMapCategoriesViewController alloc] initWithStyle:UITableViewStylePlain];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        categoriesViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonItemTapped:)];
    }
    
    MITMapBookmarksViewController *bookmarksViewController = [[MITMapBookmarksViewController alloc] initWithStyle:UITableViewStylePlain];
    bookmarksViewController.navigationItem.title = @"Bookmarks";
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        bookmarksViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonItemTapped:)];
    }
    
    MITMapRecentsTableViewController *recentsViewController = [[MITMapRecentsTableViewController alloc] init];
    recentsViewController.showsNoRecentsMessage = YES;
    recentsViewController.showsTitleHeader = NO;
    recentsViewController.navigationItem.title = @"Recents";
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        recentsViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonItemTapped:)];
    }
#warning come back and fix this ... this points to another class's method
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    recentsViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:recentsViewController action:@selector(clearRecentSearchesButtonTapped:)];
#pragma clang diagnostic pop

    self.viewControllers = @[[[UINavigationController alloc] initWithRootViewController:categoriesViewController],
                             [[UINavigationController alloc] initWithRootViewController:bookmarksViewController],
                             [[UINavigationController alloc] initWithRootViewController:recentsViewController]];
}

- (void)showViewControllerAtIndex:(NSInteger)index
{
    if (index >= [self.viewControllers count]) {
        return;
    }
    
    if ([self.viewControllers indexOfObject:self.selectedViewController] != index) {
        UIViewController *selectedViewController = self.viewControllers[index];
        selectedViewController.view.frame = self.view.bounds;
        [self addChildViewController:selectedViewController];
        [selectedViewController beginAppearanceTransition:YES animated:NO];
        [self.view addSubview:selectedViewController.view];
        [selectedViewController endAppearanceTransition];
        [selectedViewController didMoveToParentViewController:self];
        
        if (self.selectedViewController) {
            UIViewController *previousViewController = self.selectedViewController;
            [previousViewController willMoveToParentViewController:nil];
            [previousViewController.view removeFromSuperview];
            [previousViewController removeFromParentViewController];
            [previousViewController didMoveToParentViewController:nil];
        }
        
        self.selectedViewController = selectedViewController;
    }
}

#pragma mark - Delegate

- (void)setDelegate:(id <MITMapPlaceSelectionDelegate>)delegate
{
    for (UINavigationController *navigationController in self.viewControllers) {
        UIViewController *topViewController = navigationController.topViewController;
        if ([topViewController conformsToProtocol:@protocol(MITMapPlaceSelector)]) {
            [(id <MITMapPlaceSelector>)topViewController setDelegate:delegate];
        }
    }
}

#pragma mark - Actions

- (IBAction)segmentedControlValueChanged:(UISegmentedControl *)sender
{
    [self showViewControllerAtIndex:sender.selectedSegmentIndex];
}

- (void)doneButtonItemTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
