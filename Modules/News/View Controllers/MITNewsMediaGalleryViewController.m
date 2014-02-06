#import "MITNewsMediaGalleryViewController.h"
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
    if ([segue.identifier isEqualToString:@"embedPageViewController"]) {
        UIPageViewController *pageViewController = [segue destinationViewController];
        pageViewController.dataSource = self;
        pageViewController.delegate = self;
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

@end
