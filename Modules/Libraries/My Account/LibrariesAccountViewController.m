#import "LibrariesAccountViewController.h"
#import "MITTabView.h"
#import "LibrariesFinesTableController.h"
#import "LibrariesHoldsTableController.h"
#import "LibrariesLoanTableController.h"
#import "UIKit+MITAdditions.h"

@interface LibrariesAccountViewController ()
@property (nonatomic,retain) MITTabView *tabView;
@property (nonatomic,retain) id finesController;
@property (nonatomic,retain) LibrariesHoldsTableController *holdsController;
@property (nonatomic,retain) LibrariesLoanTableController *loansController;
@end

@implementation LibrariesAccountViewController
@synthesize tabView = _tabView,
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
        
        MITTabView *tabView = [[[MITTabView alloc] init] autorelease];
        tabView.frame = tabFrame;
        self.tabView = tabView;
        [mainView addSubview:tabView];
    }
    
    {
        UITableView *view = [[[UITableView alloc] initWithFrame:self.tabView.contentView.bounds
                                                          style:UITableViewStylePlain] autorelease];
        view.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
        view.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        self.loansController = [[LibrariesLoanTableController alloc] initWithTableView:view];
        [self.tabView addView:view
                     withItem:[[[UITabBarItem alloc] initWithTitle:@"Loans" image:nil tag:0] autorelease]
                      animate:NO];
    }
    
    {
        UITableView *view = [[[UITableView alloc] initWithFrame:self.tabView.contentView.bounds
                                                          style:UITableViewStylePlain] autorelease];
        view.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
        view.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        self.finesController = [[LibrariesFinesTableController alloc] initWithTableView:view];
        [self.tabView addView:view
                     withItem:[[[UITabBarItem alloc] initWithTitle:@"Fines" image:nil tag:1] autorelease]
                      animate:NO];
    }
    
    {
        UITableView *view = [[[UITableView alloc] initWithFrame:self.tabView.contentView.bounds
                                                          style:UITableViewStylePlain] autorelease];
        view.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
        view.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        self.holdsController = [[LibrariesHoldsTableController alloc] initWithTableView:view];
        [self.tabView addView:view
                     withItem:[[[UITabBarItem alloc] initWithTitle:@"Holds" image:nil tag:2] autorelease]
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
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
