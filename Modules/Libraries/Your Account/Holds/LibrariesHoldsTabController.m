#import "LibrariesHoldsTabController.h"
#import "MITLoadingActivityView.h"
#import "MobileRequestOperation.h"
#import "LibrariesHoldsTableViewCell.h"
#import "LibrariesDetailViewController.h"
#import "LibrariesAccountViewController.h"

@interface LibrariesHoldsTabController ()
@property (nonatomic,retain) MITLoadingActivityView *loadingView;
@property (nonatomic,retain) NSDictionary *loanData;

- (void)setupTableView;
- (void)updateLoanData;
@end

@implementation LibrariesHoldsTabController
@synthesize parentController = _parentController,
            tableView = _tableView;

@synthesize headerView = _headerView,
            loadingView = _loadingView,
            loanData = _loanData;

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

- (void)dealloc {
    self.parentController = nil;
    self.tableView = nil;
    self.headerView = nil;
    self.loadingView = nil;
    self.loanData = nil;
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
        
        [self.tableView addSubview:loadingView];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.loadingView = loadingView;
    }
    
    {
        LibrariesHoldsSummaryView *headerView = [[[LibrariesHoldsSummaryView alloc] initWithFrame:CGRectZero] autorelease];
        headerView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleWidth);
        self.headerView = headerView;
    }
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.isEditing == NO)
    {
        NSArray *book = [self.loanData objectForKey:@"items"];
        LibrariesDetailViewController *viewControler = [[[LibrariesDetailViewController alloc] initWithBookDetails:[book objectAtIndex:indexPath.row]
                                                                                                        detailType:LibrariesDetailHoldType] autorelease];
        [self.parentController.navigationController pushViewController:viewControler
                                                              animated:YES];
        [tableView deselectRowAtIndexPath:indexPath
                                 animated:YES];
    }
}

#pragma mark - UITableViewDataSource
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
    static NSString* LoanCellIdentifier = @"LibariesHoldsTableViewCell";
    
    LibrariesHoldsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:LoanCellIdentifier];
    
    if (cell == nil) {
        cell = [[[LibrariesHoldsTableViewCell alloc] initWithReuseIdentifier:LoanCellIdentifier] autorelease];
    }
    
    NSArray *loans = [self.loanData objectForKey:@"items"];
    cell.itemDetails = [loans objectAtIndex:indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static LibrariesHoldsTableViewCell *cell = nil;
    if (cell == nil) {
        cell = [[LibrariesHoldsTableViewCell alloc] init];
    }
    
    NSArray *loans = [self.loanData objectForKey:@"items"];
    cell.itemDetails = [loans objectAtIndex:indexPath.row];
    
    return [cell heightForContentWithWidth:CGRectGetWidth(tableView.frame) - 20.0]; // 20.0 for the accessory view
}

- (void)updateLoanData
{
    MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"libraries"
                                                                            command:@"holds"
                                                                         parameters:[NSDictionary dictionaryWithObject:[[NSNumber numberWithInteger:NSIntegerMax] stringValue]
                                                                                                                forKey:@"limit"]];
    operation.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSError *error) {
        if ([self.loadingView isDescendantOfView:self.tableView]) {
            [self.loadingView removeFromSuperview];
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        }
        
        if (error) {
            [self.parentController reportError:error
                                       fromTab:self];
        } else {
            self.loanData = (NSDictionary*)jsonResult;
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

#pragma mark - Tab Activity Notifications
- (void)tabWillBecomeActive
{
    [self updateLoanData];
}

- (void)tabDidBecomeActive
{
    
}

- (void)tabWillBecomeInactive
{
    
}

- (void)tabDidBecomeInactive
{
    
}

@end
