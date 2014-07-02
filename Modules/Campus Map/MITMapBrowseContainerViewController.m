#import "MITMapBrowseContainerViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITMapCategoriesViewController.h"

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
    [self setupSegmentedControl];
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

#pragma mark - Segmented Control Setup

- (void)setupSegmentedControl
{
    // Remove rounded corners by adding 'zero-width' segments to both ends
    [self.segmentedControl insertSegmentWithTitle:nil atIndex:0 animated:NO];
    [self.segmentedControl setWidth:CGFLOAT_MIN forSegmentAtIndex:0];
    
    [self.segmentedControl insertSegmentWithTitle:nil atIndex:self.segmentedControl.numberOfSegments animated:NO];
    [self.segmentedControl setWidth:CGFLOAT_MIN forSegmentAtIndex:self.segmentedControl.numberOfSegments - 1];
    
    [self setToolbarItems:@[[UIBarButtonItem flexibleSpace], [[UIBarButtonItem alloc] initWithCustomView:self.segmentedControl], [UIBarButtonItem flexibleSpace]] animated:NO];
}

#pragma mark - Child View Controller Management

- (void)setupViewControllers
{
    // TODO: add done bar button item to each view controller
    
    MITMapCategoriesViewController *categoriesViewController = [[MITMapCategoriesViewController alloc] initWithStyle:UITableViewStylePlain];
    
    UIViewController *bookmarksViewController = [[UIViewController alloc] init];
    bookmarksViewController.navigationItem.title = @"Bookmarks";
    bookmarksViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonItemTapped:)];
    
    UIViewController *recentsViewController = [[UIViewController alloc] init];
    recentsViewController.navigationItem.title = @"Recents";
    recentsViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonItemTapped:)];
    
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
//        selectedViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
    
    NSInteger segmentedControlIndex = index + 1;
    if (self.segmentedControl.selectedSegmentIndex != segmentedControlIndex) {
        self.segmentedControl.selectedSegmentIndex = segmentedControlIndex;
    }
}

#pragma mark - Actions

- (IBAction)segmentedControlValueChanged:(UISegmentedControl *)sender
{
    // Offset by 1 because of additional segments on both ends of control
    NSInteger viewControllerIndex = sender.selectedSegmentIndex - 1;
    [self showViewControllerAtIndex:viewControllerIndex];
}

- (void)doneButtonItemTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
