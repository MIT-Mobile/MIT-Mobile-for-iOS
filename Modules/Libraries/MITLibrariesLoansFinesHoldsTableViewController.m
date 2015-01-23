#import "MITLibrariesLoansFinesHoldsTableViewController.h"

@interface MITLibrariesLoansFinesHoldsTableViewController ()

@end

@implementation MITLibrariesLoansFinesHoldsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupRefreshControl];
}

- (void)setupRefreshControl
{
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshLoans:) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl beginRefreshing];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshLoans:(id)sender
{
    [self.refreshDelegate refreshUserData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[UITableViewCell alloc] init];
}

- (void)setItems:(NSArray *)items
{
    _items = items;
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

@end
