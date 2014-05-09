#import "LibrariesHoldsTabController.h"
#import "MITLoadingActivityView.h"
#import "LibrariesHoldsTableViewCell.h"
#import "LibrariesDetailViewController.h"
#import "LibrariesAccountViewController.h"
#import "UIKit+MITAdditions.h"

#import "MITTouchstoneRequestOperation+MITMobileV2.h"

@interface LibrariesHoldsTabController ()
@property (nonatomic,weak) MITLoadingActivityView *loadingView;
@property (copy) NSDictionary *loanData;

- (void)setupTableView;
- (void)updateLoanData;
@end

@implementation LibrariesHoldsTabController

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
        LibrariesHoldsSummaryView *headerView = [[LibrariesHoldsSummaryView alloc] initWithFrame:CGRectZero];
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
        NSArray *book = self.loanData[@"items"];
        LibrariesDetailViewController *viewControler = [[LibrariesDetailViewController alloc] initWithBookDetails:book[indexPath.row]
                                                                                                        detailType:LibrariesDetailHoldType];
        [self.parentController.navigationController pushViewController:viewControler
                                                              animated:YES];
        [tableView deselectRowAtIndexPath:indexPath
                                 animated:YES];
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.loanData[@"items"] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* LoanCellIdentifier = @"LibariesHoldsTableViewCell";
    
    LibrariesHoldsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:LoanCellIdentifier];
    
    if (cell == nil) {
        cell = [[LibrariesHoldsTableViewCell alloc] initWithReuseIdentifier:LoanCellIdentifier];
    }
    
    NSArray *loans = self.loanData[@"items"];
    cell.itemDetails = loans[indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static LibrariesHoldsTableViewCell *cell = nil;
    if (cell == nil) {
        cell = [[LibrariesHoldsTableViewCell alloc] init];
    }
    
    NSArray *loans = self.loanData[@"items"];
    cell.itemDetails = loans[indexPath.row];
    
    CGFloat accessoryWidth = (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) ? 33. : 20;
    
    return [cell heightForContentWithWidth:CGRectGetWidth(tableView.frame) - accessoryWidth];
}

- (void)updateLoanData
{
    NSURLRequest *request = [NSURLRequest requestForModule:@"libaries" command:@"holds" parameters:@{@"limit":@(NSIntegerMax)}];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

    __weak LibrariesHoldsTabController *weakSelf = self;
    requestOperation.completeBlock = ^(MITTouchstoneRequestOperation *operation, id content, NSString *contentType, NSError *error) {
        LibrariesHoldsTabController *blockSelf = weakSelf;

        if (blockSelf.loadingView) {
            [blockSelf.loadingView removeFromSuperview];
            blockSelf.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        }

        if (!blockSelf) {
            return;
        } else if (error) {
            [self.parentController reportError:error fromTab:self];
        } else {
            self.loanData = (NSDictionary*)content;
            self.headerView.accountDetails = (NSDictionary *)self.loanData;
            [self.headerView sizeToFit];
            [self.tableView reloadData];
            if (self.parentController.activeTabController == self)
            {
                [self.parentController forceTabLayout];
            }
        }
    };
    
    
    if ([self.parentController.requestOperations.operations containsObject:requestOperation] == NO) {
        [self.parentController.requestOperations addOperation:requestOperation];
    }
}

#pragma mark - Tab Activity Notifications
- (void)tabWillBecomeActive
{
    [self updateLoanData];
}

@end
