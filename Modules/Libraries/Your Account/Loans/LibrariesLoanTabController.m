#import "LibrariesLoanTabController.h"
#import "MITLoadingActivityView.h"
#import "LibrariesLoanTableViewCell.h"
#import "LibrariesRenewResultViewController.h"
#import "LibrariesDetailViewController.h"
#import "LibrariesAccountViewController.h"
#import "UIKit+MITAdditions.h"

#import "MITTouchstoneRequestOperation+MITMobileV2.h"

@interface LibrariesLoanTabController ()
@property (nonatomic, weak) MITLoadingActivityView *loadingView;
@property (nonatomic, weak) UIBarButtonItem *renewBarItem;
@property (nonatomic, weak) UIBarButtonItem *cancelBarItem;

@property (copy) NSDictionary *loanData;
@property (retain) NSMutableIndexSet *renewItems;

@property (nonatomic,weak) MITTouchstoneRequestOperation *renewOperation;
@property (nonatomic,weak) MITTouchstoneRequestOperation *loanRequestOperation;

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

    CGFloat accessoryWidth = (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) ? 33. : 20;
    
    return [cell heightForContentWithWidth:CGRectGetWidth(tableView.frame) - accessoryWidth];
}

#pragma mark -
- (void)updateLoanData
{
    NSURLRequest *request = [NSURLRequest requestForModule:@"libraries" command:@"loans" parameters:nil];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

    __weak LibrariesLoanTabController *weakSelf = self;
    requestOperation.completeBlock = ^(MITTouchstoneRequestOperation *operation, NSDictionary *content, NSString *contentType, NSError *error) {
        LibrariesLoanTabController *blockSelf = weakSelf;

        if (!blockSelf) {
            return;
        } else if (blockSelf.loanRequestOperation != operation) {
            return;
        } else {
            if ([blockSelf.loadingView isDescendantOfView:blockSelf.tableView]) {
                [blockSelf.loadingView removeFromSuperview];
                blockSelf.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
            }

            if (error || ![content isKindOfClass:[NSDictionary class]]) {
                [blockSelf.parentController reportError:error fromTab:blockSelf];
            } else {
                blockSelf.loanData = (NSDictionary*)content;
                blockSelf.headerView.renewButton.enabled = ([blockSelf.loanData[@"items"] count] > 0);
                blockSelf.headerView.accountDetails = blockSelf.loanData;
                [blockSelf.headerView sizeToFit];
                [blockSelf.tableView reloadData];
                if (blockSelf.parentController.activeTabController == blockSelf) {
                    [blockSelf.parentController forceTabLayout];
                }
            }
        }
    };

    self.headerView.renewButton.enabled = ([self.loanData[@"items"] count] > 0);

    [self.loanRequestOperation cancel];
    self.loanRequestOperation = requestOperation;
    [self.parentController.requestOperations addOperation:requestOperation];
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
        [self.parentController.navigationItem setLeftBarButtonItem:cancelBarItem
                                                          animated:YES];
        self.cancelBarItem = cancelBarItem;
    }

    if (self.renewBarItem == nil)
    {
        UIBarButtonItem *renewBarItem = [[UIBarButtonItem alloc] initWithTitle:@"Renew"
                                                                         style:UIBarButtonItemStyleDone
                                                                        target:self
                                                                        action:@selector(renewItems:)];
        [self.parentController.navigationItem setRightBarButtonItem:renewBarItem
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

    NSDictionary *parameters = @{@"barcodes" : [barcodes componentsJoinedByString:@" "]};
    NSURLRequest *request = [NSURLRequest requestForModule:@"libraries" command:@"renewBooks" parameters:parameters];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

    __weak LibrariesLoanTabController *weakSelf = self;
    [requestOperation setCompleteBlock:^(MITTouchstoneRequestOperation *operation, NSArray *content, NSString *contentType, NSError *error) {
        LibrariesLoanTabController *blockSelf = weakSelf;
        blockSelf.renewOperation = nil;

        if (!blockSelf) {
            return;
        } else if (blockSelf.renewOperation != operation) {
            return;
        } else if (error || ![content isKindOfClass:[NSArray class]]) {
            [blockSelf.parentController reportError:error fromTab:blockSelf];
            blockSelf.renewBarItem.enabled = YES;
            blockSelf.cancelBarItem.enabled = YES;
        } else {
            LibrariesRenewResultViewController *vc = [[LibrariesRenewResultViewController alloc] initWithItems:(NSArray*)content];
            [blockSelf.parentController.navigationController pushViewController:vc animated:YES];
        }

    }];

    [self.renewOperation cancel];
    self.renewOperation = requestOperation;
    [self.parentController.requestOperations addOperation:requestOperation];
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
