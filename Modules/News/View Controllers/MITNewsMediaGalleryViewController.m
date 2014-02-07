#import "MITNewsMediaGalleryViewController.h"
#import "MITNewsImageViewController.h"

#import "MITNewsImageRepresentation.h"


#import "MITAdditions.h"

@interface MITNewsMediaGalleryViewController () <UIPageViewControllerDataSource,UIPageViewControllerDelegate>

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
}

- (void)viewWillAppear:(BOOL)animated
{
    DDLogVerbose(@"View will appear!");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSAssert(self.managedObjectContext, @"parent did not assign a managed object context");

    if ([segue.identifier isEqualToString:@"embedPageViewController"]) {
        UIPageViewController *pageViewController = [segue destinationViewController];
        pageViewController.view.backgroundColor = [UIColor clearColor];

        NSMutableArray *imageViewControllers = [[NSMutableArray alloc] init];
        [self.managedObjectContext performBlockAndWait:^{
            [self.galleryImages enumerateObjectsUsingBlock:^(MITNewsImageRepresentation *imageRepresentation, NSUInteger idx, BOOL *stop) {
                MITNewsImageRepresentation *localRepresentation = imageRepresentation;
                if (localRepresentation.managedObjectContext != self.managedObjectContext) {
                    localRepresentation = (MITNewsImageRepresentation*)[self.managedObjectContext objectWithID:[imageRepresentation objectID]];
                }

                NSURL *url = localRepresentation.url;
                MITNewsImageViewController *imageViewController = [[MITNewsImageViewController alloc] initWithNibName:@"MITNewsImageViewController" bundle:nil];
                imageViewController.imageURL = url;
                [imageViewControllers addObject:imageViewControllers];
            }];

            [pageViewController setViewControllers:imageViewControllers
                                         direction:UIPageViewControllerNavigationDirectionForward
                                          animated:NO
                                        completion:nil];
        }];
    }
}

- (IBAction)dismissGallery:(id)sender
{

}

- (IBAction)shareImage:(id)sender
{

}

- (IBAction)toggleUI:(id)sender
{
    self.navigationBar.hidden = !self.navigationBar.hidden;
    self.captionView.hidden = !self.captionView.hidden;
}

#pragma mark - UIPageViewController
#pragma mark UIPageViewControllerDataSource


#pragma mark UIPageViewControllerDelegate

@end
