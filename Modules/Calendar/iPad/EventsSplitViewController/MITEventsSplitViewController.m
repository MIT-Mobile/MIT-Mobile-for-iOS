
#import "MITEventsSplitViewController.h"

static CGFloat const kMITEventHomeMasterWidthPortrait = 320.0;
static CGFloat const kMITEventHomeMasterWidthLandscape = 380.0;

@interface MITEventsSplitViewController ()
@property (nonatomic) BOOL isIOS7;
@end

@implementation MITEventsSplitViewController

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
    self.isIOS7 = (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1);
    
    if (!self.isIOS7) {
        self.minimumPrimaryColumnWidth = kMITEventHomeMasterWidthPortrait;
        self.maximumPrimaryColumnWidth = kMITEventHomeMasterWidthLandscape;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (self.isIOS7) {
        UIViewController *masterViewController = [self.viewControllers objectAtIndex:0];
        UIViewController *detailViewController = [self.viewControllers objectAtIndex:1];
        
        CGFloat targetMasterViewControllerWidth = kMITEventHomeMasterWidthPortrait;
        if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
            targetMasterViewControllerWidth = kMITEventHomeMasterWidthLandscape;
        }
        
        CGFloat currentMasterWidth = CGRectGetWidth(masterViewController.view.bounds);
        if (currentMasterWidth != targetMasterViewControllerWidth) {
            // Adjust the width of the master view
            CGRect masterViewFrame = masterViewController.view.frame;
            CGFloat deltaX = masterViewFrame.size.width - targetMasterViewControllerWidth;
            masterViewFrame.size.width -= deltaX;
            masterViewController.view.frame = masterViewFrame;
            
            // Adjust the width of the detail view
            CGRect detailViewFrame = detailViewController.view.frame;
            detailViewFrame.origin.x -= deltaX;
            detailViewFrame.size.width += deltaX;
            detailViewController.view.frame = detailViewFrame;
            
            [masterViewController.view setNeedsLayout];
            [detailViewController.view setNeedsLayout];
        }
    }
}

@end
