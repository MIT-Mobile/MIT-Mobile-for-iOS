#import "LibrariesLoanTabController.h"
#import "MITLoadingActivityView.h"
#import "MobileRequestOperation.h"
#import "LibrariesLoanTableViewCell.h"
#import "LibrariesRenewResultViewController.h"
#import "LibrariesDetailViewController.h"
#import "LibrariesAccountViewController.h"
#import "UIKit+MITAdditions.h"

@interface LibrariesLoanTabController ()
@property (nonatomic, weak) MITLoadingActivityView *loadingView;
@property (nonatomic, weak) UIBarButtonItem *renewBarItem;
@property (nonatomic, weak) UIBarButtonItem *cancelBarItem;

@property (copy) NSDictionary *loanData;
@property (copy) NSMutableIndexSet *renewItems;

@property (strong) MobileRequestOperation *renewOperation;

- (void)setupTableView;
- (void)updateLoanData;
- (IBAction)beginRenew:(id)sender;
- (IBAction)restoreTabView:(id)sender animated:(BOOL)animated;
- (IBAction)renewItems:(id)sender;
- (IBAction)cancelRenew:(id)sender;
@end

@implementation LibrariesLoanTabController
- (id)initWithTableView:(UITableView *)tableView
{
    self = [super init];
    if (self) {
        self.tableView = tableView;
        
        if (tableView) {
            [self setupTableView];
            [self updateLoanData];
        }
        
        self.loanData = [NSDictionary dictionary];
    }
    
    return self;
}

- (void)dealloc
{
    [self.renewOperation cancel];
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

- (void)setupTableView
{
    {
        CGRect loadingFrame = self.tableView.bounds;
        MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:loadingFrame];
        loadingView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                        UIViewAutoresizingFlexibleWidth);
        loadingView.backgroundColor = [UIColor whiteColor];
        loadingView.usesBackgroundImage = NO;
        
        [self.tableView addSubview:loadingView];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.loadingView = loadingView;
    }
    
    {
        CGRect headerFrame = CGRectZero;
        LibrariesLoanSummaryView *headerView = [[LibrariesLoanSummaryView alloc] initWithFrame:headerFrame];
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
    if (tableView.isEditing == NO) {
        NSArray *book = self.loanData[@"items"];
        LibrariesDetailViewController *viewControler = [[LibrariesDetailViewController alloc] initWithBookDetails:book[indexPath.row]
                                                                                                       detailType:LibrariesDetailLoanType];
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
    return [self.loanData[@"items"] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* LoanCellIdentifier = @"LibariesLoanTableViewCell";
    
    LibrariesLoanTableViewCell *cell = (LibrariesLoanTableViewCell *)[tableView dequeueReusableCellWithIdentifier:LoanCellIdentifier];
    
    if (cell == nil) {
        cell = [[LibrariesLoanTableViewCell alloc] initWithReuseIdentifier:LoanCellIdentifier];
    }

    NSArray *loans = self.loanData[@"items"];
    cell.itemDetails = loans[indexPath.row];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static LibrariesLoanTableViewCell *cell = nil;
    if (cell == nil) {
        cell = [[LibrariesLoanTableViewCell alloc] init];
    }

    NSArray *loans = self.loanData[@"items"];
    cell.itemDetails = loans[indexPath.row];
    cell.editing = tableView.isEditing;

    return [cell heightForContentWithWidth:CGRectGetWidth(tableView.frame) - 20.0]; // 20.0 for the accessory view
}

#pragma mark -
- (void)updateLoanData
{
    MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"libraries"
                                                                            command:@"loans"
                                                                         parameters:nil];
    
    self.headerView.renewButton.enabled = ([self.loanData[@"items"] count] > 0);
    
    operation.completeBlock = ^(MobileRequestOperation *operation, id content, NSString *contentType, NSError *error) {
        if ([self.loadingView isDescendantOfView:self.tableView]) {
            [self.loadingView removeFromSuperview];
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        }
        
        if (error) {
            [self.parentController reportError:error
                                       fromTab:self];
        } else {
            self.loanData = (NSDictionary*)content;
            self.headerView.renewButton.enabled = ([self.loanData[@"items"] count] > 0);
            self.headerView.accountDetails = (NSDictionary *)self.loanData;
            [self.headerView sizeToFit];
            [self.tableView reloadData];
            if (self.parentController.activeTabController == self)
            {
                [self.parentController forceTabLayout];
            }
        }
    };
    
    if ([self.parentController.requestOperations.operations containsObject:operation] == NO)
    {
        [self.parentController.requestOperations addOperation:operation];
    }
}


#pragma mark - Event Handlers
- (IBAction)beginRenew:(id)sender
{
    self.renewItems = [NSMutableIndexSet indexSet];

    if (self.cancelBarItem == nil)
    {
        UIBarButtonItem *cancelBarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                 target:self
                                                                                 action:@selector(cancelRenew:)];
        [self.parentController.navigationItem setRightBarButtonItem:self.renewBarItem
                                                           animated:YES];
        self.cancelBarItem = cancelBarItem;
    }

    if (self.renewBarItem == nil)
    {
        UIBarButtonItem *renewBarItem = [[UIBarButtonItem alloc] initWithTitle:@"Renew"
                                                                         style:UIBarButtonItemStyleDone
                                                                        target:self
                                                                        action:@selector(renewItems:)];
        [self.parentController.navigationItem setLeftBarButtonItem:self.cancelBarItem
                                                          animated:YES];
        self.renewBarItem = renewBarItem;
    }
    
    self.renewBarItem.enabled = NO;
    
    [self.parentController.navigationItem setHidesBackButton:YES animated:YES];

    if ([self.tabViewHidingDelegate conformsToProtocol:@protocol(MITTabViewHidingDelegate)]) {
        [self.tabViewHidingDelegate setTabBarHidden:YES animated:YES];
    }

    [self.tableView setEditing:YES animated:YES];
}

- (IBAction)restoreTabView:(id)sender animated:(BOOL)animated
{
    self.renewItems = nil;
    self.cancelBarItem.enabled = YES;

    [self.parentController.navigationItem setHidesBackButton:NO animated:animated];
    [self.parentController.navigationItem setRightBarButtonItem:nil animated:animated];
    [self.parentController.navigationItem setLeftBarButtonItem:nil animated:animated];

    [self.tableView setEditing:NO animated:animated];
    if ([self.tabViewHidingDelegate conformsToProtocol:@protocol(MITTabViewHidingDelegate)]) {
        [self.tabViewHidingDelegate setTabBarHidden:NO animated:animated];
    }
}

- (IBAction)renewItems:(id)sender
{
    NSMutableArray *barcodes = [NSMutableArray array];
    NSArray *bookDetails = self.loanData[@"items"];

    [self.renewItems enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSString *barcode = bookDetails[idx][@"barcode"];
        if (barcode) {
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
    [operation setCompleteBlock:^(MobileRequestOperation *operation, id content, NSString *contentType, NSError *error) {
        self.renewOperation = nil;
        
        if (error)
        {
            [self.parentController reportError:error fromTab:self];
            self.renewBarItem.enabled = YES;
            self.cancelBarItem.enabled = YES;
        }
        else
        {
            LibrariesRenewResultViewController *vc = [[LibrariesRenewResultViewController alloc] initWithItems:(NSArray*)content];
            [self.parentController.navigationController pushViewController:vc
                                                                  animated:YES];
        }

    }];
    
    self.renewOperation = operation;
    [self.parentController.requestOperations addOperation:operation];
}

- (IBAction)cancelRenew:(id)sender
{
    if (self.renewOperation)
    {
        [self.renewOperation cancel];
    }

    [self restoreTabView:sender animated:YES];
}

#pragma mark - Tab Activity Notifications
- (void)tabWillBecomeActive
{
    [self restoreTabView:nil animated:NO];
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

@end
