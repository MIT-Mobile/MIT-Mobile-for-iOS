#import "LibrariesAccountViewController.h"
#import "LibrariesFinesTabController.h"
#import "LibrariesHoldsTabController.h"
#import "LibrariesLoanTabController.h"
#import "UIKit+MITAdditions.h"
#import "MITLogging.h"

// keep this order in sync with view instantiation in loadView below
typedef enum {
    LibrariesActiveTabLoans = 0,
    LibrariesActiveTabFines,
    LibrariesActiveTabHolds,
    LibrariesActiveTabInvalid = NSNotFound
} LibrariesActiveTabType;

@interface LibrariesAccountViewController ()
@property (strong) NSOperationQueue *requestOperations;
@property (nonatomic,weak) MITTabView *tabView;
@property LibrariesActiveTabType activeTabIndex;
@property (nonatomic,strong) NSMutableArray *barItems;
@property (nonatomic,strong) NSMutableArray *tabControllers;
@property BOOL alertIsActive;
@end

@implementation LibrariesAccountViewController
@dynamic activeTabController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.activeTabIndex = LibrariesActiveTabLoans;
        self.barItems = [NSMutableArray array];
        self.tabControllers = [NSMutableArray array];
        
        self.requestOperations = [[NSOperationQueue alloc] init];
        self.requestOperations.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        
        if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
    }
    
    return self;
}

- (void)dealloc {
    self.activeTabIndex = LibrariesActiveTabInvalid;
    [self.requestOperations cancelAllOperations];
}

- (id)activeTabController
{
    return self.tabControllers[self.activeTabIndex];
}

#pragma mark - View lifecycle
- (void)loadView
{
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    screenRect.origin.y += CGRectGetHeight(self.navigationController.navigationBar.frame);
    screenRect.size.height -= CGRectGetHeight(self.navigationController.navigationBar.frame);
    
    UIView *mainView = [[UIView alloc] initWithFrame:screenRect];
    mainView.autoresizesSubviews = YES;
    
    mainView.backgroundColor = [UIColor colorWithHexString:@"f7f7f7"];
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        mainView.backgroundColor = [UIColor mit_backgroundColor];
    }

    
    {
        MITTabView *tabView = [[MITTabView alloc] init];
        tabView.autoresizesSubviews = YES;
        tabView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                     UIViewAutoresizingFlexibleWidth |
                                    UIViewAutoresizingFlexibleBottomMargin);
        tabView.frame = mainView.bounds;
        self.tabView = tabView;
        [mainView addSubview:tabView];
    }
    
    // keep this order in sync with LibrariesActiveTabType enum above
    {
        UITableView *view = [[UITableView alloc] initWithFrame:CGRectZero
                                                          style:UITableViewStylePlain];
        view.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
        view.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        LibrariesLoanTabController *tabController = [[LibrariesLoanTabController alloc] initWithTableView:view];
        tabController.parentController = self;
        tabController.tabViewHidingDelegate = self.tabView;
        
        UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:@"Loans"
                                                           image:nil
                                                             tag:LibrariesActiveTabLoans];
        [self.barItems addObject:item];
        [self.tabControllers addObject:tabController];
        [self.tabView addView:view
                     withItem:item
                      animate:NO];
    }
    
    {
        UITableView *view = [[UITableView alloc] initWithFrame:CGRectZero
                                                          style:UITableViewStylePlain];
        view.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
        view.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        LibrariesFinesTabController *tabController = [[LibrariesFinesTabController alloc] initWithTableView:view];
        tabController.parentController = self;
        
        UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:@"Fines"
                                                           image:nil
                                                             tag:LibrariesActiveTabFines];
        [self.barItems addObject:item];
        [self.tabControllers addObject:tabController];
        [self.tabView addView:view
                     withItem:item
                      animate:NO];
    }
    
    {
        UITableView *view = [[UITableView alloc] initWithFrame:CGRectZero
                                                         style:UITableViewStylePlain];
        view.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
        view.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        LibrariesHoldsTabController *tabController = [[LibrariesHoldsTabController alloc] initWithTableView:view];
        tabController.parentController = self;
        
        UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:@"Holds"
                                                           image:nil
                                                             tag:LibrariesActiveTabHolds];
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
        case LibrariesActiveTabLoans: {
            id tabController = self.tabControllers[LibrariesActiveTabLoans];
            if ([tabController respondsToSelector:@selector(tabWillBecomeActive)]) {
                [tabController tabWillBecomeActive];
            }
        }
            
        case LibrariesActiveTabFines:
        case LibrariesActiveTabHolds:
            [self.tabView selectTabAtIndex:self.activeTabIndex];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.activeTabIndex == LibrariesActiveTabLoans) {
        id tabController = self.tabControllers[LibrariesActiveTabLoans];
        if ([tabController respondsToSelector:@selector(tabWillBecomeActive)]) {
            [tabController tabWillBecomeActive];
        }
    }
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - MITTabViewDelegate Methods
- (void)tabView:(MITTabView*)tabView viewWillBecomeActive:(UIView*)view
{
    [self.tabControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (view == [obj tableView])
        {
            if ([obj respondsToSelector:@selector(tabWillBecomeActive)]) {
                [obj tabWillBecomeActive];
            }
            
            *stop = YES;
        }
    }];
}

- (void)tabView:(MITTabView*)tabView viewDidBecomeActive:(UIView*)view
{
    [self.tabControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (view == [obj tableView]) {
            if ([obj respondsToSelector:@selector(tabDidBecomeActive)]) {
                [obj tabDidBecomeActive];
            }
            
            self.activeTabIndex = (LibrariesActiveTabType)idx;
            *stop = YES;
        }
    }];
}

- (void)tabView:(MITTabView*)tabView viewWillBecomeInactive:(UIView*)view
{
    [self.tabControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (view == [obj tableView]) {
            if ([obj respondsToSelector:@selector(tabWillBecomeInactive)]) {
                [obj tabWillBecomeInactive];
            }
            
            *stop = YES;
        }
    }];
}

- (void)tabView:(MITTabView*)tabView viewDidBecomeInactive:(UIView*)view
{
    [self.tabControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (view == [obj tableView])
        {
            if ([obj respondsToSelector:@selector(tabDidBecomeInactive)]) {
                [obj performSelector:@selector(tabDidBecomeInactive)];
            }
            
            *stop = YES;
        }
    }];
}


- (CGFloat)tabView:(MITTabView*)tabView heightOfHeaderForView:(UIView*)view
{
    __block CGFloat height = 0;
    [self.tabControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (view == [obj tableView]) {
            UIView *header = [obj headerView];
            
            CGRect frame = header.frame;
            frame.size.width = tabView.bounds.size.width;
            header.frame = frame;
            [header sizeToFit];
            
            height = CGRectGetHeight(header.frame);
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
    
    DDLogVerbose(@"Tab <%@> encountered an error: %@", [self.barItems[type] title], [error localizedDescription]);
    
    if ((self.alertIsActive == NO) && (self.activeTabIndex == type))
    {
        if ((error.code == MITMobileRequestInvalidLoginError) || (error.code == NSUserCancelledError))
        {
            [self.requestOperations cancelAllOperations];
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.title
                                                             message:[error localizedDescription]
                                                            delegate:self
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:@"OK",nil];
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
