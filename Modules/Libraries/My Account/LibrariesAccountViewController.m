#import "LibrariesAccountViewController.h"
#import "LibrariesFinesTableController.h"
#import "LibrariesHoldsTableController.h"
#import "LibrariesLoanTableController.h"
#import "UIKit+MITAdditions.h"

@interface LibrariesAccountViewController ()
@property (nonatomic,retain) MITTabView *tabView;
@property (nonatomic,retain) LibrariesFinesTableController *finesController;
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
    screenRect.origin.y += CGRectGetHeight(self.navigationController.navigationBar.frame);
    screenRect.size.height -= CGRectGetHeight(self.navigationController.navigationBar.frame);
    
    UIView *mainView = [[[UIView alloc] initWithFrame:screenRect] autorelease];
    
    {
        MITTabView *tabView = [[[MITTabView alloc] init] autorelease];
        tabView.frame = mainView.bounds;
        tabView.delegate = self;
        self.tabView = tabView;
        [mainView addSubview:tabView];
    }
    
    {
        UITableView *view = [[[UITableView alloc] initWithFrame:CGRectZero
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
        UITableView *view = [[[UITableView alloc] initWithFrame:CGRectZero
                                                          style:UITableViewStylePlain] autorelease];
        view.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
        view.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        self.finesController = [[LibrariesFinesTableController alloc] initWithTableView:view];
        
        UITabBarItem *item = [[[UITabBarItem alloc] initWithTitle:@"Fines"
                                                               image:nil
                                                                 tag:1] autorelease];
        [self.tabView addView:view
                     withItem:item
                      animate:NO];
    }
    
    {
        UITableView *view = [[[UITableView alloc] initWithFrame:CGRectZero
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

#pragma mark - MITTabViewDelegate Methods
- (void)tabView:(MITTabView*)tabView viewWillBecomeActive:(UIView*)view
{
    if (view == self.finesController.tableView)
    {
        [self.finesController tabWillBecomeActive];
    }
    else if (view == self.holdsController.tableView)
    {
        [self.holdsController tabWillBecomeActive];
    }
    else if (view == self.loansController.tableView)
    {
        [self.loansController tabWillBecomeActive];
    }
}

- (void)tabView:(MITTabView*)tabView viewDidBecomeActive:(UIView*)view
{
    if (view == self.finesController.tableView)
    {
        [self.finesController tabDidBecomeActive];
    }
    else if (view == self.holdsController.tableView)
    {
        [self.holdsController tabDidBecomeActive];
    }
    else if (view == self.loansController.tableView)
    {
        [self.loansController tabDidBecomeActive];
    }
}

- (void)tabView:(MITTabView*)tabView viewWillBecomeInactive:(UIView*)view
{
    if (view == self.finesController.tableView)
    {
        [self.finesController tabDidBecomeInactive];
    }
    else if (view == self.holdsController.tableView)
    {
        [self.holdsController tabDidBecomeInactive];
    }
    else if (view == self.loansController.tableView)
    {
        [self.loansController tabDidBecomeInactive];
    }
}

- (void)tabView:(MITTabView*)tabView viewDidBecomeInactive:(UIView*)view
{
    if (view == self.finesController.tableView)
    {
        [self.finesController tabWillBecomeInactive];
    }
    else if (view == self.holdsController.tableView)
    {
        [self.holdsController tabWillBecomeInactive];
    }
    else if (view == self.loansController.tableView)
    {
        [self.loansController tabWillBecomeInactive];
    }
}

@end
