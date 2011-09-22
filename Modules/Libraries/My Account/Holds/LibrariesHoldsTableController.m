#import "LibrariesHoldsTableController.h"
#import "LibrariesHoldsSummaryView.h"
#import "MITLoadingActivityView.h"
#import "MobileRequestOperation.h"
#import "LibrariesHoldsTableViewCell.h"

@interface LibrariesHoldsTableController ()
@property (nonatomic,retain) LibrariesHoldsSummaryView *headerView;
@property (nonatomic,retain) MITLoadingActivityView *loadingView;
@property (nonatomic,retain) NSDictionary *loanData;

- (void)setupTableView;
- (void)updateLoanData;
@end

@implementation LibrariesHoldsTableController
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
        LibrariesHoldsSummaryView *headerView = [[[LibrariesHoldsSummaryView alloc] initWithFrame:headerFrame] autorelease];
        headerView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleWidth);
        self.headerView = headerView;
    }
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

#pragma mark - UITableViewDelegate

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
        cell = [[[LibrariesHoldsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                  reuseIdentifier:LoanCellIdentifier] autorelease];
    }
    
    NSArray *loans = [self.loanData objectForKey:@"items"];
    NSDictionary *loanDetails = [loans objectAtIndex:indexPath.row];
    [cell setItemDetails:loanDetails];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LibrariesHoldsTableViewCell *cell = [[[LibrariesHoldsTableViewCell alloc] init] autorelease];
    NSArray *loans = [self.loanData objectForKey:@"items"];
    [cell setItemDetails:[loans objectAtIndex:indexPath.row]];
    CGSize size = [cell sizeThatFits:CGSizeMake(tableView.bounds.size.width, 0)];
    
    return size.height;
}

- (void)updateLoanData
{
    if (self.loanData == nil)
    {
        self.loadingView.frame = self.tableView.bounds;
        [self.tableView addSubview:self.loadingView];
        self.tableView.scrollEnabled = NO;
    }
    
    MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"libraries"
                                                                            command:@"holds"
                                                                         parameters:[NSDictionary dictionaryWithObject:[[NSNumber numberWithInteger:NSIntegerMax] stringValue]
                                                                                                                forKey:@"limit"]];
    operation.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSError *error) {
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        } else {
            if (self.loadingView.superview != nil) {
                [self.loadingView removeFromSuperview];
                self.tableView.scrollEnabled = YES;
            }
            
            self.loanData = (NSDictionary*)jsonResult;
            [self.tableView reloadData];
        }
    };
    [operation start];
}

@end
