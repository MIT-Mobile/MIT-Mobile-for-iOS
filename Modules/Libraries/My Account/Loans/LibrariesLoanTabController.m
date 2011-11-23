#import "LibrariesLoanTabController.h"
#import "MITLoadingActivityView.h"
#import "MobileRequestOperation.h"
#import "LibrariesLoanTableViewCell.h"
#import "LibrariesRenewResultViewController.h"
#import "LibrariesDetailViewController.h"

@interface LibrariesLoanTabController ()
@property (nonatomic,retain) MITLoadingActivityView *loadingView;

@property (nonatomic,retain) NSDictionary *loanData;
@property (nonatomic, retain) NSMutableIndexSet *renewItems;
@property (nonatomic, retain) UIBarButtonItem *renewBarItem;
@property (nonatomic, retain) UIBarButtonItem *cancelBarItem;

@property (nonatomic,retain) MobileRequestOperation *operation;

- (void)setupTableView;
- (void)updateLoanData;
@end

@implementation LibrariesLoanTabController
@synthesize parentController = _parentController;
@synthesize tableView = _tableView;
@synthesize tabView = _tabView;

@synthesize headerView = _headerView;
@synthesize loadingView = _loadingView;
@synthesize loanData = _loanData;

@synthesize renewItems = _renewItems;
@synthesize renewBarItem = _renewBarItem;
@synthesize cancelBarItem = _cancelBarItem;


@synthesize operation = _operation;

- (id)initWithTableView:(UITableView *)tableView
{
    self = [super init];
    if (self) {
        self.tableView = tableView;
        
        if (tableView) {
            [self setupTableView];
            [self updateLoanData];
        }
    }
    
    return self;
}

- (void)dealloc
{
    self.parentController = nil;
    self.tableView = nil;
    self.tabView = nil;
    self.headerView = nil;
    self.loadingView = nil;
    self.loanData = nil;
    self.operation = nil;
    self.renewItems = nil;
    self.renewBarItem = nil;
    self.cancelBarItem = nil;

    [super dealloc];
}

- (void)setupTableView
{
    {
        CGRect loadingFrame = self.tableView.bounds;
        MITLoadingActivityView *loadingView = [[[MITLoadingActivityView alloc] initWithFrame:loadingFrame] autorelease];
        loadingView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                        UIViewAutoresizingFlexibleWidth);
        loadingView.backgroundColor = [UIColor whiteColor];
        loadingView.usesBackgroundImage = NO;
        self.loadingView = loadingView;
    }
    
    {
        CGRect headerFrame = CGRectZero;
        LibrariesLoanSummaryView *headerView = [[[LibrariesLoanSummaryView alloc] initWithFrame:headerFrame] autorelease];
        headerView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleWidth);
        [headerView.renewButton addTarget:self
                                   action:@selector(beginRenew:)
                         forControlEvents:UIControlEventTouchUpInside];
        headerView.renewButton.enabled = NO;
        
        self.headerView = headerView;
    }
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsSelection = YES;
}

#pragma mark - UITableViewDelegate
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *selectedIndex = nil;
    
    if (tableView.isEditing)
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

        if (cell)
        {
            if ([self.renewItems containsIndex:indexPath.row])
            {
                [self.renewItems removeIndex:indexPath.row];
                cell.selected = NO;
            }
            else
            {
                [self.renewItems addIndex:indexPath.row];
                cell.selected = YES;
            }
        }

        self.renewBarItem.enabled = ([self.renewItems count] > 0);
    }
    else
    {
        selectedIndex = indexPath;
    }
    
    return selectedIndex;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.isEditing == NO)
    {
        NSArray *book = [self.loanData objectForKey:@"items"];
        LibrariesDetailViewController *viewControler = [[[LibrariesDetailViewController alloc] initWithBookDetails:[book objectAtIndex:indexPath.row]
                                                                                                        detailType:LibrariesDetailLoanType] autorelease];
        [self.parentController.navigationController pushViewController:viewControler
                                                              animated:YES];
        [tableView deselectRowAtIndexPath:indexPath
                                 animated:YES];
    }
}

#pragma mark - UITableViewDataSource
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *items = [self.loanData objectForKey:@"items"];
    return [items count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* LoanCellIdentifier = @"LibariesLoanTableViewCell";
    
    LibrariesLoanTableViewCell *cell = (LibrariesLoanTableViewCell *)[tableView dequeueReusableCellWithIdentifier:LoanCellIdentifier];
    
    if (cell == nil) {
        cell = [[[LibrariesLoanTableViewCell alloc] initWithReuseIdentifier:LoanCellIdentifier] autorelease];
    }

    NSArray *loans = [self.loanData objectForKey:@"items"];
    cell.itemDetails = [loans objectAtIndex:indexPath.row];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static LibrariesLoanTableViewCell *cell = nil;
    if (cell == nil) {
        cell = [[LibrariesLoanTableViewCell alloc] init];
    }

    NSArray *loans = [self.loanData objectForKey:@"items"];
    cell.itemDetails = [loans objectAtIndex:indexPath.row];
    cell.editing = tableView.isEditing;

    return [cell heightForContentWithWidth:CGRectGetWidth(tableView.frame)];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.isEditing)
    {
        cell.selected = [self.renewItems containsIndex:indexPath.row];
    }
}


#pragma mark -
- (void)updateLoanData
{
    if (self.loanData == nil)
    {
        self.loadingView.frame = self.tableView.frame;
        [self.tableView.superview insertSubview:self.loadingView
                                   aboveSubview:self.tableView];
    }
    
    if (self.operation == nil)
    {
        NSDictionary *requestLimit = [NSDictionary dictionaryWithObject:[[NSNumber numberWithInteger:NSIntegerMax] stringValue]
                                                                 forKey:@"limit"];
        MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"libraries"
                                                                                command:@"loans"
                                                                             parameters:requestLimit];
        self.headerView.renewButton.enabled = NO;
        operation.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSError *error) {
            if (error) {
                ELog(@"Loan: %@", [error localizedDescription]);
                DLog(@"Data:\n-----\n%@\n-----", jsonResult);
                [self.parentController.navigationController popViewControllerAnimated:YES];
            } else {
                if (self.loadingView.superview != nil) {
                    [self.loadingView removeFromSuperview];
                }
                
                self.loanData = (NSDictionary*)jsonResult;
            }

            self.headerView.renewButton.enabled = ([[self.loanData objectForKey:@"items"] count] > 0);
            self.headerView.accountDetails = (NSDictionary *)self.loanData;
            [self.headerView sizeToFit];

            [self.tableView reloadData];
            [self.tableView beginUpdates];
            [self.tableView endUpdates];
            
            self.operation = nil;
        };
    
        self.operation = operation;
        [operation start];
    }
}


#pragma mark - Event Handlers
- (IBAction)beginRenew:(id)sender
{
    //LibrariesRenewViewController *vc = [[[LibrariesRenewViewController alloc] initWithItems:[self.loanData objectForKey:@"items"]] autorelease];
    //[self.parentController.navigationController pushViewController:vc
    //                                                      animated:YES];

    self.renewItems = [NSMutableIndexSet indexSet];

    if (self.cancelBarItem == nil)
    {
        self.cancelBarItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                 target:self
                                                                                 action:@selector(cancelRenew:)] autorelease];
    }

    if (self.renewBarItem == nil)
    {
        self.renewBarItem = [[[UIBarButtonItem alloc] initWithTitle:@"Renew"
                                                              style:UIBarButtonItemStyleDone
                                                             target:self
                                                             action:@selector(renewItems:)] autorelease];
    }
    
    [self.parentController.navigationItem setHidesBackButton:YES animated:YES];
    [self.parentController.navigationItem setRightBarButtonItem:self.renewBarItem
                                                       animated:YES];
    [self.parentController.navigationItem setLeftBarButtonItem:self.cancelBarItem
                                                      animated:YES];

    [self.tabView setTabBarHidden:YES animated:YES];

    [self.tableView setEditing:YES animated:YES];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];

}

- (IBAction)restoreTabView:(id)sender
{
    self.renewItems = nil;
    self.cancelBarItem.enabled = YES;

    [self.parentController.navigationItem setHidesBackButton:NO animated:YES];
    [self.parentController.navigationItem setRightBarButtonItem:nil animated:YES];
    [self.parentController.navigationItem setLeftBarButtonItem:nil animated:YES];

    [self.tableView setEditing:NO animated:YES];
    [self.tabView setTabBarHidden:NO
                         animated:YES];
}

- (IBAction)renewItems:(id)sender
{
    NSMutableArray *barcodes = [NSMutableArray array];
    NSArray *bookDetails = [self.loanData objectForKey:@"items"];

    [self.renewItems enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSDictionary *book = [bookDetails objectAtIndex:idx];
        NSString *barcode = [book objectForKey:@"barcode"];
        if (barcode)
        {
            [barcodes addObject:barcode];
        }

    }];

    self.cancelBarItem.enabled = NO;
    self.renewBarItem.enabled = NO;

    NSDictionary *params = [NSDictionary dictionaryWithObject:[barcodes componentsJoinedByString:@" "]
                                                       forKey:@"barcodes"];
    MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"libraries"
                                                                            command:@"renewBooks"
                                                                         parameters:params];
    [operation setCompleteBlock:^(MobileRequestOperation *operation, id jsonData, NSError *error) {
        self.operation = nil;
        
        if (error)
        {
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Renew"
                                                             message:[error localizedDescription]
                                                            delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
            [alert show];
            self.renewBarItem.enabled = YES;
            self.cancelBarItem.enabled = YES;
        }
        else
        {
            LibrariesRenewResultViewController *vc = [[[LibrariesRenewResultViewController alloc] initWithItems:(NSArray*)jsonData] autorelease];
            [self.parentController.navigationController pushViewController:vc
                                                                  animated:YES];
            [self restoreTabView:sender];
        }

    }];

    self.operation = operation;
    [operation start];
}

- (IBAction)cancelRenew:(id)sender
{
    if (self.operation)
    {
        [self.operation cancel];
    }

    [self restoreTabView:sender];
}

#pragma mark - Tab Activity Notifications
- (void)tabWillBecomeActive
{
}

- (void)tabDidBecomeActive
{
    [self updateLoanData];
}

- (void)tabWillBecomeInactive
{
    [self.parentController.navigationItem setRightBarButtonItem:nil
                                                       animated:YES];
}

- (void)tabDidBecomeInactive
{
    
}

@end
