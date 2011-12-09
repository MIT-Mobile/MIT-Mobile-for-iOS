#import "LibrariesAccountViewController.h"
#import "LibrariesFinesTabController.h"
#import "LibrariesHoldsTabController.h"
#import "LibrariesLoanTabController.h"
#import "UIKit+MITAdditions.h"

// keep this order in sync with view instantiation in loadView below
typedef enum {
    LibrariesActiveTabLoans = 0,
    LibrariesActiveTabFines,
    LibrariesActiveTabHolds,
    LibrariesActiveTabInvalid = NSNotFound
} LibrariesActiveTabType;

@interface LibrariesAccountViewController ()
@property (nonatomic,retain) NSOperationQueue *requestOperations;
@property (nonatomic,retain) MITTabView *tabView;
@property (nonatomic,assign) LibrariesActiveTabType activeTabIndex;
@property (nonatomic,retain) NSMutableArray *barItems;
@property (nonatomic,retain) NSMutableArray *tabControllers;
@property (nonatomic) BOOL alertIsActive;
@end

@implementation LibrariesAccountViewController
@synthesize tabView = _tabView,
            activeTabIndex = _activeTabIndex,
            barItems = _barItems,
            tabControllers = _tabControllers,
            alertIsActive = _alertIsActive,
            requestOperations = _requestOperations;

@dynamic activeTabController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.activeTabIndex = LibrariesActiveTabLoans;
        self.barItems = [NSMutableArray array];
        self.tabControllers = [NSMutableArray array];
        
        self.requestOperations = [[[NSOperationQueue alloc] init] autorelease];
        self.requestOperations.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    }
    return self;
}

- (void)dealloc {
    self.activeTabIndex = LibrariesActiveTabInvalid;
    [self.requestOperations cancelAllOperations];
    
    self.tabView = nil;
    self.barItems = nil;
    self.tabControllers = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (id)activeTabController
{
    return [self.tabControllers objectAtIndex:self.activeTabIndex];
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
        
        LibrariesLoanTabController *tabController = [[[LibrariesLoanTabController alloc] initWithTableView:view] autorelease];
        tabController.parentController = self;
        tabController.tabViewHidingDelegate = self.tabView;
        
        UITabBarItem *item = [[[UITabBarItem alloc] initWithTitle:@"Loans"
                                                            image:nil
                                                              tag:LibrariesActiveTabLoans] autorelease];
        [self.barItems addObject:item];
        [self.tabControllers addObject:tabController];
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
        
        LibrariesFinesTabController *tabController = [[[LibrariesFinesTabController alloc] initWithTableView:view] autorelease];
        tabController.parentController = self;
        
        UITabBarItem *item = [[[UITabBarItem alloc] initWithTitle:@"Fines"
                                                            image:nil
                                                              tag:LibrariesActiveTabFines] autorelease];
        [self.barItems addObject:item];
        [self.tabControllers addObject:tabController];
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
        
        LibrariesHoldsTabController *tabController = [[[LibrariesHoldsTabController alloc] initWithTableView:view] autorelease];
        tabController.parentController = self;
        
        UITabBarItem *item = [[[UITabBarItem alloc] initWithTitle:@"Holds"
                                                            image:nil
                                                              tag:LibrariesActiveTabHolds] autorelease];
        [self.barItems addObject:item];
        [self.tabControllers addObject:tabController];
        [self.tabView addView:view
                     withItem:item
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
    self.tabControllers = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    switch (self.activeTabIndex) {
        default:
        case LibrariesActiveTabLoans:
            [[self.tabControllers objectAtIndex:LibrariesActiveTabLoans] tabWillBecomeActive];
        case LibrariesActiveTabFines:
        case LibrariesActiveTabHolds:
            [self.tabView selectTabAtIndex:self.activeTabIndex];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.activeTabIndex == LibrariesActiveTabLoans) {
        [[self.tabControllers objectAtIndex:LibrariesActiveTabLoans] tabDidBecomeActive];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - MITTabViewDelegate Methods
- (void)tabView:(MITTabView*)tabView viewWillBecomeActive:(UIView*)view
{
    [self.tabControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (view == [obj tableView])
        {
            [obj tabWillBecomeActive];
            *stop = YES;
        }
    }];
}

- (void)tabView:(MITTabView*)tabView viewDidBecomeActive:(UIView*)view
{
    [self.tabControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (view == [obj tableView])
        {
            [obj tabDidBecomeActive];
            self.activeTabIndex = (LibrariesActiveTabType)idx;
            *stop = YES;
        }
    }];
}

- (void)tabView:(MITTabView*)tabView viewWillBecomeInactive:(UIView*)view
{
    [self.tabControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (view == [obj tableView])
        {
            [obj tabWillBecomeInactive];
            *stop = YES;
        }
    }];
}

- (void)tabView:(MITTabView*)tabView viewDidBecomeInactive:(UIView*)view
{
    [self.tabControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (view == [obj tableView])
        {
            [obj tabDidBecomeInactive];
            *stop = YES;
        }
    }];
}


- (CGFloat)tabView:(MITTabView*)tabView heightOfHeaderForView:(UIView*)view
{
    __block CGFloat height = 0;
    [self.tabControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (view == [obj tableView])
        {
            UIView *header = [obj headerView];
            CGSize size = [header sizeThatFits:tabView.bounds.size];
            height = size.height;
            *stop = YES;
        }
    }];

    return height;
}

- (UIView*)tabView:(MITTabView*)tabView headerForView:(UIView*)view
{
    __block UIView *headerView = nil;
    [self.tabControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (view == [obj tableView])
        {
            headerView = [obj headerView];
            *stop = YES;
        }
    }];
    
    return headerView;
}

- (void)reportError:(NSError*)error fromTab:(id)tabController;
{
    if (error == nil)
    {
        error = [NSError errorWithDomain:NSURLErrorDomain
                                    code:NSURLErrorUnknown
                                userInfo:nil];
    }
    
    LibrariesActiveTabType type = (LibrariesActiveTabType)[self.tabControllers indexOfObject:tabController];
    if (type == LibrariesActiveTabInvalid)
    {
        return;
    }
    
    DLog(@"Tab <%@> encountered an error: %@", [[self.barItems objectAtIndex:type] title], [error localizedDescription]);
    
    if ((self.alertIsActive == NO) && (self.activeTabIndex == type))
    {
        if ((error.code == MobileWebInvalidLoginError) || (error.code == NSUserCancelledError))
        {
            [self.requestOperations cancelAllOperations];
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:self.title
                                                             message:[error localizedDescription]
                                                            delegate:self
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:@"OK",nil] autorelease];
            self.alertIsActive = YES;
            [alert show];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.alertIsActive = NO;
}

- (void)forceTabLayout
{
    [self.tabView setNeedsLayout];
}
@end
