#import "MITImageGalleryViewController.h"
#import "MITImageScrollViewController.h"

@interface MITImageGalleryViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (nonatomic, getter = isInterfaceHidden) BOOL interfaceHidden;
@property (nonatomic, getter = isStatusBarHidden) BOOL statusBarHidden;
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *toggleUIGestureRecognizer;
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *toggleZoomGestureRecognizer;

- (IBAction)dismissGallery:(id)sender;
- (IBAction)toggleUI:(id)sender;
- (IBAction)toggleZoom:(id)sender;

@end

@implementation MITImageGalleryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Overriding the tint color in the xib doesn't work, so override it here in code.
    self.navigationBar.tintColor = [UIColor whiteColor];
    
    [self.toggleUIGestureRecognizer requireGestureRecognizerToFail:self.toggleZoomGestureRecognizer];
    
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:@{UIPageViewControllerOptionInterPageSpacingKey : @(5.0)}];
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    self.pageViewController.view.frame = self.view.bounds;
    [self addChildViewController:self.pageViewController];
    [self.view insertSubview:self.pageViewController.view atIndex:0];
    [self.pageViewController didMoveToParentViewController:self];

    [self reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (IBAction)dismissGallery:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)toggleUI:(id)sender
{
    [self setInterfaceHidden:!self.isInterfaceHidden animated:YES];
}

- (IBAction)toggleZoom:(id)sender {
    MITImageScrollViewController *currentVC = self.pageViewController.viewControllers[0];
    [currentVC toggleZoom];
}

- (void)setDataSource:(id<MITImageGalleryDataSource>)dataSource {
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        [self reloadData];
    }
}

- (MITImageScrollViewController *)viewControllerForIndex:(NSInteger)index {
    MITImageScrollViewController *vc = [[MITImageScrollViewController alloc] init];
    vc.index = index;
    vc.imageURL = [self.dataSource gallery:self imageURLAtIndex:index];
    return vc;
}

- (void)reloadData {
    NSInteger count = [self.dataSource numberOfImagesInGallery:self];
    NSInteger index = 0;
    if (count > 0) {
        [self.pageViewController setViewControllers:@[[self viewControllerForIndex:index]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
        [self updateNavTitleIndex:index];
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    MITImageScrollViewController *scrollViewController = (MITImageScrollViewController *)viewController;
    NSInteger current = scrollViewController.index;
    NSInteger count = [self.dataSource numberOfImagesInGallery:self];
    
    NSInteger before = current - 1;
    if (before >= 0 && before < count) {
        MITImageScrollViewController *vc = [[MITImageScrollViewController alloc] init];
        vc.index = before;
        return vc;
    } else {
        return nil;
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    MITImageScrollViewController *scrollViewController = (MITImageScrollViewController *)viewController;
    NSInteger current = scrollViewController.index;
    NSInteger count = [self.dataSource numberOfImagesInGallery:self];
    
    NSInteger after = current + 1;
    if (after >= 0 && after < count) {
        MITImageScrollViewController *vc = [[MITImageScrollViewController alloc] init];
        vc.index = after;
        return vc;
    } else {
        return nil;
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    NSArray *newViewControllers = pageViewController.viewControllers;
    MITImageScrollViewController *scrollViewController = (MITImageScrollViewController *)newViewControllers[0];
    NSInteger newIndex = scrollViewController.index;
    [self updateNavTitleIndex:newIndex];
}

- (void)updateNavTitleIndex:(NSInteger)index {
    UINavigationItem *navigationItem = [[self.navigationBar items] lastObject];
    NSInteger count = [self.dataSource numberOfImagesInGallery:self];
    navigationItem.title = [NSString stringWithFormat:@"%ld of %ld", (long)index + 1, (long)count];
}

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

- (void)setInterfaceHidden:(BOOL)interfaceHidden animated:(BOOL)animated
{
    if (_interfaceHidden != interfaceHidden) {
        _interfaceHidden = interfaceHidden;
        
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            _statusBarHidden = YES;
        } else {
            _statusBarHidden = interfaceHidden;
        }
        if (!_interfaceHidden) {
            [self setNeedsStatusBarAppearanceUpdate];
        }
        
        CGFloat alpha = (_interfaceHidden ? 0.0 : 1.0);
        [UIView animateWithDuration:(animated ? 0.3 : 0)
                         animations:^{
                             self.navigationBar.alpha = alpha;
                             if (_interfaceHidden) {
                                 [self setNeedsStatusBarAppearanceUpdate];
                             }
                         }];
    }
}

@end
