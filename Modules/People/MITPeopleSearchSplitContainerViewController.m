#import "MITPeopleSearchSplitContainerViewController.h"

@interface MITPeopleSearchSplitContainerViewController ()

@property (nonatomic, weak) UIViewController *masterViewController;
@property (nonatomic, weak) UIViewController *detailsViewController;

@property (nonatomic, weak) IBOutlet UIView *lineSeparator;
@property (nonatomic, weak) IBOutlet UIView *masterViewContainer;
@property (nonatomic, weak) IBOutlet UIView *detailsViewContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *masterViewContainerWidthConstraint;

@end

static CGFloat masterViewContainerWidthLandscape = 410;
static CGFloat masterViewContainerWidthPortrait  = 320;

@implementation MITPeopleSearchSplitContainerViewController

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
    [super viewWillAppear:animated];
}

- (void)viewWillLayoutSubviews
{
    if( UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) )
    {
        [self adjustMasterViewWidthForOrientation:[UIApplication sharedApplication].statusBarOrientation];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self adjustMasterViewWidthForOrientation:toInterfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    NSLog(@"");
}

- (void)adjustMasterViewWidthForOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
    
    self.masterViewContainerWidthConstraint.constant = isLandscape ? masterViewContainerWidthLandscape : masterViewContainerWidthPortrait;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if( [segue.identifier isEqualToString:@"MITMasterController"] )
    {
        self.masterViewController = [segue destinationViewController];
    }
    else if( [segue.identifier isEqualToString:@"MITDetailsController"] )
    {
        self.detailsViewController = [segue destinationViewController];
    }
}

@end
