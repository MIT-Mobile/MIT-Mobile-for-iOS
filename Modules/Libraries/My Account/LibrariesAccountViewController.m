#import "LibrariesAccountViewController.h"
#import "MITTabViewController.h"
#import "LibrariesFinesViewController.h"
#import "LibrariesHoldsViewController.h"
#import "LibrariesLoansViewController.h"

@interface LibrariesAccountViewController ()
@property (nonatomic,retain) MITTabViewController *tabViewController;
@property (nonatomic,retain) LibrariesFinesViewController *finesController;
@property (nonatomic,retain) LibrariesHoldsViewController *holdsController;
@property (nonatomic,retain) LibrariesLoansViewController *loansController;
@end

@implementation LibrariesAccountViewController
@synthesize tabViewController = _tabViewController,
            finesController = _finesController,
            holdsController = _holdsController,
            loansController = _loansController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (void)loadView
{
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    UIView *mainView = [[[UIView alloc] initWithFrame:screenRect] autorelease];
    
    {
        CGRect tabFrame = screenRect;
        tabFrame.origin = CGPointZero;
        
        MITTabViewController *tabView = [[[MITTabViewController alloc] init] autorelease];
        tabView.view.frame = tabFrame;
        self.tabViewController = tabView;
        [mainView addSubview:tabView.view];
    }
    
    {
        LibrariesLoansViewController *controller = [[[LibrariesLoansViewController alloc] init] autorelease];
        controller.title = @"Loans";
        self.loansController = controller;
        [self.tabViewController addViewController:controller
                                          animate:NO]; 
    }
    
    {
        LibrariesFinesViewController *controller = [[[LibrariesFinesViewController alloc] init] autorelease];
        controller.title = @"Fines";
        self.finesController = controller;
        [self.tabViewController addViewController:controller
                                          animate:NO]; 
    }
    
    {
        LibrariesHoldsViewController *controller = [[[LibrariesHoldsViewController alloc] init] autorelease];
        controller.title = @"Holds";
        self.holdsController = controller;
        [self.tabViewController addViewController:controller
                                          animate:NO]; 
    }
    
    [self setView:mainView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tabViewController viewWillAppear:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.tabViewController viewWillDisappear:animated];
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
