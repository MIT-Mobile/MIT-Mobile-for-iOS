#import "LibrariesFinesTabController.h"
#import "MITLoadingActivityView.h"
#import "MobileRequestOperation.h"
#import "LibrariesFinesTableViewCell.h"
#import "LibrariesDetailViewController.h"
#import "LibrariesAccountViewController.h"
#import "UIKit+MITAdditions.h"

@interface LibrariesFinesTabController ()
@property (nonatomic,weak) MITLoadingActivityView *loadingView;
@property (copy) NSDictionary *loanData;

- (void)setupTableView;
- (void)updateLoanData;
@end

@implementation LibrariesFinesTabController
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
        LibrariesFinesSummaryView *headerView = [[LibrariesFinesSummaryView alloc] initWithFrame:CGRectZero];
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
                                                                                                        detailType:LibrariesDetailFineType];
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
    static NSString* LoanCellIdentifier = @"LibariesFinesTableViewCell";
    
    LibrariesFinesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:LoanCellIdentifier];
    
    if (cell == nil) {
        cell = [[LibrariesFinesTableViewCell alloc] initWithReuseIdentifier:LoanCellIdentifier];
    }
    
    NSArray *loans = self.loanData[@"items"];
    cell.itemDetails = loans[indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static LibrariesFinesTableViewCell *cell = nil;
    if (cell == nil) {
        cell = [[LibrariesFinesTableViewCell alloc] init];
    }
    
    NSArray *loans = self.loanData[@"items"];
    cell.itemDetails = loans[indexPath.row];
    
    return [cell heightForContentWithWidth:CGRectGetWidth(tableView.frame) - 20.0]; // 20.0 for the accessory view
}

- (void)updateLoanData
{
    NSString *limitString = [NSString stringWithFormat:@"%ld", NSIntegerMax];
    MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"libraries"
                                                                            command:@"fines"
                                                                         parameters:@{@"limit" : limitString}];
    
    __weak LibrariesFinesTabController *weakSelf = self;
    operation.completeBlock = ^(MobileRequestOperation *operation, id content, NSString *contentType, NSError *error) {
        LibrariesFinesTabController *blockSelf = weakSelf;
        if (blockSelf) {
            if (blockSelf.loadingView) {
                [blockSelf.loadingView removeFromSuperview];
                blockSelf.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
            }
            
            if (error) {
                [blockSelf.parentController reportError:error
                                           fromTab:self];
            } else {
                blockSelf.loanData = (NSDictionary*)content;
                blockSelf.headerView.accountDetails = (NSDictionary *)blockSelf.loanData;
                [blockSelf.headerView sizeToFit];
                [blockSelf.tableView reloadData];
                if (blockSelf.parentController.activeTabController == self)
                {
                    [blockSelf.parentController forceTabLayout];
                }
            }
        }
    };
    
    if ([self.parentController.requestOperations.operations containsObject:operation] == NO) {
        [self.parentController.requestOperations addOperation:operation];
    }
}

#pragma mark - Tab Activity Notifications
- (void)tabWillBecomeActive
{
    [self updateLoanData];
}

@end
