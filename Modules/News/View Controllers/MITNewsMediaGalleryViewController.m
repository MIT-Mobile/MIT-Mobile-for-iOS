#import "MITNewsMediaGalleryViewController.h"
#import "MITCoreDataController.h"
#import "MITNewsImageViewController.h"

#import "MITNewsImageRepresentation.h"
#import "MITNewsImage.h"


#import "MITAdditions.h"

@interface MITNewsMediaGalleryViewController () <UIPageViewControllerDataSource,UIPageViewControllerDelegate>
@property (nonatomic) BOOL shouldHideUI;
@property (nonatomic,strong) NSMutableArray *galleryPageViewControllers;
@property (nonatomic) NSInteger selectedIndex;

@end

@implementation MITNewsMediaGalleryViewController

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
    self.title = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    // Call this to force an update of the image caption
    // for the first view controller
    [self didChangeSelectedIndex];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (NSArray*)galleryImages
{
    return [_galleryImages arrayByMappingObjectsUsingBlock:^id(MITNewsImage *newsImage, NSUInteger idx) {
        if (newsImage.managedObjectContext != self.managedObjectContext) {
            return (MITNewsImage*)[self.managedObjectContext objectWithID:[newsImage objectID]];
        } else {
            return newsImage;
        }
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSAssert(self.managedObjectContext, @"parent did not assign a managed object context");

    if ([segue.identifier isEqualToString:@"embedPageViewController"]) {
        UIPageViewController *pageViewController = [segue destinationViewController];
        pageViewController.dataSource = self;
        pageViewController.delegate = self;
        pageViewController.view.backgroundColor = [UIColor clearColor];

        NSMutableArray *galleryPageViewControllers = [[NSMutableArray alloc] init];
        [self.managedObjectContext performBlockAndWait:^{
            [self.galleryImages enumerateObjectsUsingBlock:^(MITNewsImage *image, NSUInteger idx, BOOL *stop) {
                MITNewsImageViewController *imageViewController = [[MITNewsImageViewController alloc] initWithNibName:@"MITNewsImageViewController" bundle:nil];
                
                NSManagedObjectContext *context = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:NO];
                imageViewController.managedObjectContext = context;
                imageViewController.image = (MITNewsImage*)[context objectWithID:[image objectID]];
                
                [galleryPageViewControllers addObject:imageViewController];
            }];
            

            self.galleryPageViewControllers = galleryPageViewControllers;
            [pageViewController setViewControllers:@[[galleryPageViewControllers firstObject]]
                                         direction:UIPageViewControllerNavigationDirectionForward
                                          animated:NO
                                        completion:nil];
        }];
    }
}

#pragma mark Properties
- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    if (_selectedIndex != selectedIndex) {
        _selectedIndex = selectedIndex;
        
        [self didChangeSelectedIndex];
    }
}

#pragma mark UI Actions
- (IBAction)dismissGallery:(id)sender
{

}

- (IBAction)shareImage:(id)sender
{
    if (self.selectedIndex != NSNotFound) {
        NSMutableArray *items = [[NSMutableArray alloc] init];
        
        MITNewsImageViewController *currentViewController = self.galleryPageViewControllers[self.selectedIndex];
        if (currentViewController.cachedImage) {
            [items addObject:currentViewController.cachedImage];
        }
        
        [self.managedObjectContext performBlockAndWait:^{
            NSArray *galleryImages = self.galleryImages;
            MITNewsImage *image = galleryImages[self.selectedIndex];
            
            if ([items count] == 0) {
               MITNewsImageRepresentation *imageRepresentation = [image bestRepresentationForSize:MITNewsImageLargestImageSize];
                [items addObject:imageRepresentation.url];
            }
            
            if (image.caption) {
                [items addObject:image.caption];
            } else if (image.descriptionText) {
                [items addObject:image.descriptionText];
            }
        }];
        
        UIActivityViewController *sharingViewController = [[UIActivityViewController alloc] initWithActivityItems:items
                                                                                            applicationActivities:nil];
        sharingViewController.excludedActivityTypes = @[UIActivityTypePrint,
                                                        UIActivityTypeAssignToContact,
                                                        UIActivityTypeSaveToCameraRoll];
        
        [self presentViewController:sharingViewController animated:YES completion:nil];
    } else {
        DDLogWarn(@"attempting to share an image with an index of NSNotFound");
    }
}

- (IBAction)toggleUI:(id)sender
{
    if (self.shouldHideUI) {
        self.shouldHideUI = NO;
    } else {
        self.shouldHideUI = YES;
    }


    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:self.shouldHideUI withAnimation:UIStatusBarAnimationNone];
    }

    self.navigationBar.hidden = !self.navigationBar.hidden;
    self.captionView.hidden = !self.captionView.hidden;
}

- (void)didChangeSelectedIndex
{
    if (self.selectedIndex != NSNotFound) {
        UINavigationItem *navigationItem = [[self.navigationBar items] lastObject];
        navigationItem.title = [NSString stringWithFormat:@"%d of %d",self.selectedIndex + 1,[_galleryImages count]];
        
        __block NSString *description = nil;
        __block NSString *credits = nil;
        [self.managedObjectContext performBlockAndWait:^{
            MITNewsImage *image = self.galleryImages[self.selectedIndex];
            description = image.descriptionText;
            credits = image.credits;
        }];
        
        self.descriptionLabel.text = description;
        self.creditLabel.text = credits;
    }
}

- (BOOL)prefersStatusBarHidden {
    return self.shouldHideUI;
}

#pragma mark - UIPageViewController
#pragma mark UIPageViewControllerDataSource
- (UIViewController*)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[MITNewsImageViewController class]]) {
        MITNewsImageViewController *galleryImageViewController = (MITNewsImageViewController*)viewController;
        NSUInteger galleryImageIndex = [self.galleryPageViewControllers indexOfObject:galleryImageViewController];
        if (galleryImageIndex == NSNotFound) {
            // No idea where this object came from.
            DDLogWarn(@"[%@] asked to create a page for an unknown object '%@'",self,galleryImageViewController);
            return nil;
        } else if (galleryImageIndex == ([self.galleryImages count] - 1)) {
            // This is the last page so we just return nil here
            return nil;
        } else {
            return self.galleryPageViewControllers[galleryImageIndex + 1];
        }
    } else {
        return nil;
    }
}

- (UIViewController*)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[MITNewsImageViewController class]]) {
        MITNewsImageViewController *galleryImageViewController = (MITNewsImageViewController*)viewController;
        NSUInteger galleryImageIndex = [self.galleryPageViewControllers indexOfObject:galleryImageViewController];
        if (galleryImageIndex == NSNotFound) {
            // No idea where this object came from.
            DDLogWarn(@"[%@] asked to create a page for an unknown object '%@'",self,galleryImageViewController);
            return nil;
        } else if (galleryImageIndex == 0) {
            // This is the last page so we just return nil here
            return nil;
        } else {
            return self.galleryPageViewControllers[galleryImageIndex - 1];
        }
    } else {
        return nil;
    }
}

#pragma mark UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed) {
        NSMutableOrderedSet *viewControllers = [[NSMutableOrderedSet alloc] initWithArray:[pageViewController viewControllers]];
        NSOrderedSet *previousViewControllersSet = [NSOrderedSet orderedSetWithArray:previousViewControllers];
        
        // TODO: See if this is even need or if we can just use -[NSOrderedSet lastObject]
        if (![previousViewControllersSet isEqualToOrderedSet:viewControllers]) {
            [viewControllers minusSet:[NSSet setWithArray:previousViewControllers]];
        }
        
        MITNewsImageViewController *imageViewController = [viewControllers firstObject];
        if (imageViewController) {
            self.selectedIndex = [self.galleryPageViewControllers indexOfObject:imageViewController];
        } else {
            DDLogWarn(@"unable to pick a selected index in for the gallery");
            self.selectedIndex = NSNotFound;
        }
    }
}

@end
