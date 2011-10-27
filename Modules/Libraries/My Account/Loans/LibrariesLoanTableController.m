#import "LibrariesLoanTableController.h"
#import "MITLoadingActivityView.h"
#import "MobileRequestOperation.h"
#import "LibrariesLoanTableViewCell.h"

@interface LibrariesLoanTableController ()
@property (nonatomic,retain) MITLoadingActivityView *loadingView;
@property (nonatomic,retain) NSDictionary *loanData;
@property (nonatomic,retain) MobileRequestOperation *operation;
@property (nonatomic,retain) NSDate *lastUpdate;
@property (nonatomic,retain) UIBarButtonItem *editButton;

- (void)setupTableView;
- (void)updateLoanData;
@end

@implementation LibrariesLoanTableController
@synthesize parentController = _parentController,
            tableView = _tableView;

@synthesize headerView = _headerView,
            loadingView = _loadingView,
            loanData = _loanData,
            operation = _operation,
            lastUpdate = _lastUpdate,
            editButton = _editButton;

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

- (void)setupTableView
{
    {
        CGRect loadingFrame = self.tableView.bounds;
        MITLoadingActivityView *loadingView = [[[MITLoadingActivityView alloc] initWithFrame:loadingFrame] autorelease];
        loadingView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                        UIViewAutoresizingFlexibleWidth);
        loadingView.backgroundColor = [UIColor whiteColor];
        self.loadingView = loadingView;
    }
    
    {
        CGRect headerFrame = CGRectZero;
        LibrariesLoanSummaryView *headerView = [[[LibrariesLoanSummaryView alloc] initWithFrame:headerFrame] autorelease];
        headerView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleWidth);
        self.headerView = headerView;
    }
    
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

#pragma mark - UITableViewDelegate
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - UITableViewDataSource
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *items = [self.loanData objectForKey:@"items"];
    if (items) {
        return [items count];
    } else {
        return 0;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* LoanCellIdentifier = @"LibariesLoanTableViewCell";
    
    LibrariesLoanTableViewCell *cell = (LibrariesLoanTableViewCell *)[tableView dequeueReusableCellWithIdentifier:LoanCellIdentifier];
    
    if (cell == nil) {
        cell = [[[LibrariesLoanTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                  reuseIdentifier:LoanCellIdentifier] autorelease];
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
    
    CGFloat width = (tableView.isEditing ? kLibrariesTableCellEditingWidth : kLibrariesTableCellDefaultWidth);

    return [cell heightForContentWithWidth:width];
}

- (void)updateLoanData
{
    if (self.loanData == nil)
    {
        self.loadingView.frame = self.tableView.frame;
        [self.tableView.superview insertSubview:self.loadingView
                                   aboveSubview:self.tableView];
    }
    
    BOOL shouldUpdate = (self.lastUpdate == nil) || ([self.lastUpdate timeIntervalSinceNow] > 15.0);
    
    if ((self.operation == nil) && shouldUpdate)
    {
        MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"libraries"
                                                                                command:@"loans"
                                                                             parameters:[NSDictionary dictionaryWithObject:[[NSNumber numberWithInteger:NSIntegerMax] stringValue]
                                                                                                                    forKey:@"limit"]];
        operation.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSError *error) {
            if (error) {
                ELog(@"Loan: %@", [error localizedDescription]);
                [self.parentController.navigationController popViewControllerAnimated:YES];
            } else {
                if (self.loadingView.superview != nil) {
                    [self.loadingView removeFromSuperview];
                }
                
                self.lastUpdate = [NSDate date];
                self.loanData = (NSDictionary*)jsonResult;
                [self.tableView reloadData];
            }
            
            self.operation = nil;
        };
    
        self.operation = operation;
        [operation start];
    }
}

- (void)edit:(id)sender
{
    
    UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                   target:self
                                                                                   action:@selector(cancel:)] autorelease];
    [self.parentController.navigationItem setRightBarButtonItem:cancelButton
                                                       animated:YES];
    [self.tableView beginUpdates];
    [self.tableView setEditing:YES];
    [self.tableView endUpdates];
}

- (void)cancel:(id)sender
{
    UIBarButtonItem *editButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                 target:self
                                                                                 action:@selector(edit:)] autorelease];
    [self.parentController.navigationItem setRightBarButtonItem:editButton
                                                       animated:YES];
    [self.tableView beginUpdates];
    [self.tableView setEditing:NO];
    [self.tableView endUpdates];
}

#pragma mark - Tab Activity Notifications
- (void)tabWillBecomeActive
{
}

- (void)tabDidBecomeActive
{
    [self updateLoanData];
    
    if (self.parentController.navigationItem) 
    {
        if (self.tableView.isEditing) {
            [self edit:nil];
        } else {
            [self cancel:nil];
        }
    }
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
