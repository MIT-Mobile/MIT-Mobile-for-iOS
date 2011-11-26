#import "LibrariesAccountViewController.h"
#import "LibrariesFinesTabController.h"
#import "LibrariesHoldsTabController.h"
#import "LibrariesLoanTabController.h"
#import "UIKit+MITAdditions.h"

// keep this order in sync with view instantiation in loadView below
typedef enum {
    LibrariesActiveTabLoans = 0,
    LibrariesActiveTabFines,
    LibrariesActiveTabHolds
} LibrariesActiveTabType;

@interface LibrariesAccountViewController ()
@property (nonatomic,retain) MITTabView *tabView;
@property (nonatomic,assign) LibrariesActiveTabType activeTabIndex;
@property (nonatomic,retain) LibrariesFinesTabController *finesController;
@property (nonatomic,retain) LibrariesHoldsTabController *holdsController;
@property (nonatomic,retain) LibrariesLoanTabController *loansController;
@end

@implementation LibrariesAccountViewController
@synthesize tabView = _tabView,
            activeTabIndex = _activeTabIndex,
            finesController = _finesController,
            holdsController = _holdsController,
            loansController = _loansController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.activeTabIndex = LibrariesActiveTabLoans;
    }
    return self;
}

- (void)dealloc {
    self.tabView = nil;
    self.loansController = nil;
    self.finesController = nil;
    self.holdsController = nil;
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
        self.tabView = tabView;
        [mainView addSubview:tabView];
    }
    
    // keep this order in sync with LibrariesActiveTabType enum above
    {
        UITableView *view = [[[UITableView alloc] initWithFrame:CGRectZero
                                                          style:UITableViewStylePlain] autorelease];
        view.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
        view.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        self.loansController = [[[LibrariesLoanTabController alloc] initWithTableView:view] autorelease];
        self.loansController.parentController = self;
        self.loansController.tabViewHidingDelegate = self.tabView;
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
        
        self.finesController = [[[LibrariesFinesTabController alloc] initWithTableView:view] autorelease];
        self.finesController.parentController = self;
        
        [self.tabView addView:view
                     withItem:[[[UITabBarItem alloc] initWithTitle:@"Fines" image:nil tag:1] autorelease]
                      animate:NO];
    }
    
    {
        UITableView *view = [[[UITableView alloc] initWithFrame:CGRectZero
                                                          style:UITableViewStylePlain] autorelease];
        view.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
        view.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        self.holdsController = [[[LibrariesHoldsTabController alloc] initWithTableView:view] autorelease];
        self.holdsController.parentController = self;
        [self.tabView addView:view
                     withItem:[[[UITabBarItem alloc] initWithTitle:@"Holds" image:nil tag:2] autorelease]
                      animate:NO];
    }
    
    // define this late so that tab additions during initialization don't overwrite any self.activeTabIndex carried over between memory warnings
    self.tabView.delegate = self;
    
    [self setView:mainView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Your Account";
}


- (void)viewDidUnload
{
    [self.tabView removeFromSuperview];
    self.tabView = nil;
    self.loansController = nil;
    self.finesController = nil;
    self.holdsController = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    switch (self.activeTabIndex) {
        case LibrariesActiveTabLoans:
            [self.loansController tabWillBecomeActive];
        case LibrariesActiveTabFines:
        case LibrariesActiveTabHolds:
            [self.tabView selectTabAtIndex:self.activeTabIndex];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.activeTabIndex == LibrariesActiveTabLoans) {
        [self.loansController tabDidBecomeActive];
    }
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
        self.activeTabIndex = LibrariesActiveTabFines;
    }
    else if (view == self.holdsController.tableView)
    {
        [self.holdsController tabDidBecomeActive];
        self.activeTabIndex = LibrariesActiveTabHolds;
    }
    else if (view == self.loansController.tableView)
    {
        [self.loansController tabDidBecomeActive];
        self.activeTabIndex = LibrariesActiveTabLoans;
    }
}

- (void)tabView:(MITTabView*)tabView viewWillBecomeInactive:(UIView*)view
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

- (void)tabView:(MITTabView*)tabView viewDidBecomeInactive:(UIView*)view
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


- (CGFloat)tabView:(MITTabView*)tabView heightOfHeaderForView:(UIView*)view
{
    if (view == self.finesController.tableView)
    {
        UIView *header = self.finesController.headerView;
        CGSize size = [header sizeThatFits:tabView.bounds.size];
        return size.height;
    }
    else if (view == self.holdsController.tableView)
    {
        UIView *header = self.holdsController.headerView;
        CGSize size = [header sizeThatFits:tabView.bounds.size];
        return size.height;
    }
    else if (view == self.loansController.tableView)
    {
        UIView *header = self.loansController.headerView;
        CGSize size = [header sizeThatFits:tabView.bounds.size];
        return size.height;
    }
    
    return 0.0;
}

- (UIView*)tabView:(MITTabView*)tabView headerForView:(UIView*)view
{
    if (view == self.finesController.tableView)
    {
        return self.finesController.headerView;
    }
    else if (view == self.holdsController.tableView)
    {
        return self.holdsController.headerView;
    }
    else if (view == self.loansController.tableView)
    {
        return self.loansController.headerView;
    }
    
    return nil;
}


@end
