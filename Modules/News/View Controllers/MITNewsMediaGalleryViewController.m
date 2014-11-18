#import "MITNewsMediaGalleryViewController.h"
#import "MITCoreDataController.h"
#import "MITNewsImageViewController.h"

#import "MITNewsImageRepresentation.h"
#import "MITNewsImage.h"

#import "MITImageScrollView.h"

#import "MITAdditions.h"

#import "ThumbnailPickerView.h"

#import "UIImageView+WebCache.h"

@interface MITNewsMediaGalleryViewController () <UIPageViewControllerDataSource,UIPageViewControllerDelegate, ThumbnailPickerViewDataSource, ThumbnailPickerViewDelegate, UIGestureRecognizerDelegate, UIBarPositioningDelegate, UINavigationBarDelegate>
@property (nonatomic,weak) IBOutlet UIGestureRecognizer *toggleUIGesture;
@property (nonatomic,weak) IBOutlet UIGestureRecognizer *resetZoomGesture;
@property (nonatomic,getter = isInterfaceHidden) BOOL interfaceHidden;
@property (nonatomic,getter = isStatusBarHidden) BOOL statusBarHidden;
@property (nonatomic,strong) NSMutableArray *galleryPageViewControllers;
@property (nonatomic) NSInteger selectedIndex;

@property (nonatomic, strong) NSMutableArray *thumbnailImages;
@property (strong, nonatomic) IBOutlet ThumbnailPickerView *thumbnailPickerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navigationBarHeightConstraint;

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


- (IBAction)unwindToStoryDetail:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^() {
        [self performSegueWithIdentifier:@"unwindFromImageGallery" sender:self];
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    self.title = nil;

    self.toggleUIGesture.delegate = self;
    [self.toggleUIGesture requireGestureRecognizerToFail:self.resetZoomGesture];
    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.navigationBar.delegate = self;
    self.navigationBar.tintColor = [UIColor whiteColor];
    
    self.view.backgroundColor = [UIColor blackColor];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Call this to force an update of the image caption
    // for the first view controller
    [self didChangeSelectedIndex];
    [self.thumbnailPickerView setSelectedIndex:0];
    [self setPhoneNavigationBarHeight:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setPhoneNavigationBarHeight:toInterfaceOrientation];
}

- (void)viewWillLayoutSubviews
{
    self.navigationBarHeightConstraint.constant = self.navigationBar.intrinsicContentSize.height;
    [self.view setNeedsLayout];
    [self.view updateConstraintsIfNeeded];
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

- (NSMutableArray*)thumbnailImages
{
    if (!_thumbnailImages) {
        NSMutableArray *thumbnailImages = [[NSMutableArray alloc] init];
        
        for(int i = 0 ; i < [self.galleryImages count] ; i++) {
            [thumbnailImages addObject:[NSNull null]];
        }
        _thumbnailImages = thumbnailImages;
        }
    return _thumbnailImages;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSAssert(self.managedObjectContext, @"parent did not assign a managed object context");

    if ([segue.identifier isEqualToString:@"embedPageViewController"]) {
        self.pageViewController = [segue destinationViewController];
        self.pageViewController.dataSource = self;
        self.pageViewController.delegate = self;
        self.pageViewController.view.backgroundColor = [UIColor clearColor];

        NSMutableArray *galleryPageViewControllers = [[NSMutableArray alloc] init];
        [self.managedObjectContext performBlockAndWait:^{
            [self.galleryImages enumerateObjectsUsingBlock:^(MITNewsImage *image, NSUInteger idx, BOOL *stop) {
                MITNewsImageViewController *imageViewController = [[MITNewsImageViewController alloc] initWithNibName:@"MITNewsImageViewController" bundle:nil];
                
                NSManagedObjectContext *context = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:NO];
                imageViewController.managedObjectContext = context;
                imageViewController.image = (MITNewsImage*)[context objectWithID:[image objectID]];
                
                [galleryPageViewControllers addObject:imageViewController];
                
                if (self.thumbnailPickerView) {
                    __block NSURL *imageURL = nil;
                    
                    __weak MITNewsMediaGalleryViewController *weak = self;
                    
                    MITNewsImageRepresentation *imageRepresentation = [imageViewController.image bestRepresentationForSize:MITNewsImageSmallestImageSize];
                    imageURL = imageRepresentation.url;
                    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL
                                                                          options:0
                                                                         progress:nil
                                                                        completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                            MITNewsMediaGalleryViewController *strong = weak;
                                                                            if (image) {
                                                                                [strong.thumbnailImages replaceObjectAtIndex:idx withObject:image];
                                                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                                                    [strong.thumbnailPickerView reloadThumbnailAtIndex:idx];
                                                                                });
                                                                            }
                                                                        }];
                }
            }];
            
            
            self.galleryPageViewControllers = galleryPageViewControllers;
            [self.pageViewController setViewControllers:@[[galleryPageViewControllers firstObject]]
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
        [self.thumbnailPickerView setSelectedIndex:selectedIndex animated:YES];
    }
}

#pragma mark UI Actions

- (void)goToIndex:(NSInteger)selectedIndex {
    if (selectedIndex > [self.galleryPageViewControllers count]) {
        return;
    }

    const NSUInteger minimumIndex = MIN(selectedIndex,self.selectedIndex);
    const NSUInteger maximumIndex = MAX(selectedIndex,self.selectedIndex);
    const NSUInteger length = (maximumIndex + 1) - minimumIndex;

    UIPageViewControllerNavigationDirection direction = UIPageViewControllerNavigationDirectionForward;
    NSEnumerationOptions enumerationOptions = 0;

    if (selectedIndex < self.selectedIndex) {
        direction = UIPageViewControllerNavigationDirectionReverse;
        enumerationOptions |= NSEnumerationReverse;
    }

    NSIndexSet *imageControllerIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(minimumIndex, length)];

    [self.galleryPageViewControllers enumerateObjectsAtIndexes:imageControllerIndexes
                                                       options:enumerationOptions
                                                    usingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        [self.pageViewController setViewControllers:@[viewController] direction:direction animated:NO completion:nil];
    }];

    self.selectedIndex = selectedIndex;
}

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

            if (image.caption) {
                [items addObject:image.caption];
            } else if (image.descriptionText) {
                [items addObject:image.descriptionText];
            }
            if (self.storyLink) {
                [items addObject:[NSString stringWithFormat:@"\n%@",self.storyLink.relativeString]];
            }
        }];
        
        UIActivityViewController *sharingViewController = [[UIActivityViewController alloc] initWithActivityItems:items
                                                                                            applicationActivities:nil];
        
        sharingViewController.excludedActivityTypes = @[UIActivityTypePrint,
                                                        UIActivityTypeAssignToContact];
        
        [sharingViewController setValue:[NSString stringWithFormat:@"MIT News: %@",self.storyTitle] forKeyPath:@"subject"];
        
        if ([sharingViewController respondsToSelector:@selector(popoverPresentationController)]) {
            sharingViewController.popoverPresentationController.barButtonItem = sender;
        }
        [self presentViewController:sharingViewController animated:YES completion:nil];
    } else {
        DDLogWarn(@"attempting to share an image with an index of NSNotFound");
    }
}

- (IBAction)resetZoom:(UIGestureRecognizer*)sender
{
    MITNewsImageViewController *currentViewController = self.galleryPageViewControllers[self.selectedIndex];
    [currentViewController.scrollView resetZoom];
}

- (IBAction)toggleUI:(UIGestureRecognizer*)sender
{
    [self setInterfaceHidden:!self.isInterfaceHidden animated:YES];
}

- (void)setInterfaceHidden:(BOOL)interfaceHidden
{
    [self setInterfaceHidden:interfaceHidden animated:NO];
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
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
        
        CGFloat alpha = (_interfaceHidden ? 0. : 1);
        [UIView animateWithDuration:(animated ? 0.33 : 0)
                              delay:0
                            options:0
                         animations:^{
                             self.captionView.alpha = alpha;
                             self.navigationBar.alpha = alpha;
                         } completion:^(BOOL finished) {
                             if (_interfaceHidden) {
                                 [self setNeedsStatusBarAppearanceUpdate];
                             }
                         }];
    }
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

- (void)setPhoneNavigationBarHeight:(UIInterfaceOrientation)orientation
{
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        _statusBarHidden = YES;
    } else {
        _statusBarHidden = _interfaceHidden;
    }
    [self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
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

#pragma mark - Private API

- (void)_updateUIWithSelectedIndex:(NSUInteger)index
{
    [self goToIndex:index];
}

#pragma mark - ThumbnailPickerView data source

- (NSUInteger)numberOfImagesForThumbnailPickerView:(ThumbnailPickerView *)thumbnailPickerView
{
    return [self.galleryImages count];
}

- (UIImage *)thumbnailPickerView:(ThumbnailPickerView *)thumbnailPickerView imageAtIndex:(NSUInteger)index
{
    UIImage *image;
    if ([self.thumbnailImages count] > index  && [self.thumbnailImages objectAtIndex:index] != [NSNull null]) {
       image = [self.thumbnailImages objectAtIndex:index];
    }
    return image;
}

#pragma mark - ThumbnailPickerView delegate

- (void)thumbnailPickerView:(ThumbnailPickerView *)thumbnailPickerView didSelectImageWithIndex:(NSUInteger)index
{
    [self _updateUIWithSelectedIndex:index];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([gestureRecognizer isEqual:self.toggleUIGesture]) {
        CGPoint touchPoint = [touch locationInView:self.thumbnailPickerView];

        if (CGRectContainsPoint(self.thumbnailPickerView.bounds,touchPoint)) {
            return NO;
        }
    }

    return YES;
}
@end
