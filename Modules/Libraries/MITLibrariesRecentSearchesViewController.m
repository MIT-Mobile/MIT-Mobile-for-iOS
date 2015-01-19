#import "MITLibrariesRecentSearchesViewController.h"
#import "MITLibrariesWebservices.h"

static NSString *const kMITLibrariesRecentsCell = @"kMITLibrariesRecentsCell";

@interface MITLibrariesRecentSearchesViewController ()

@property (nonatomic, strong) NSArray *recentSearchStrings;

@end

@implementation MITLibrariesRecentSearchesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Recents";
    
    [self setupNavBar];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateRecentSearchStrings];
}

- (void)setupNavBar
{
    UIBarButtonItem *clearRecentsButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearRecentsPressed:)];
    self.navigationItem.leftBarButtonItem = clearRecentsButton;
}

- (void)updateRecentSearchStrings
{
    self.recentSearchStrings = [MITLibrariesWebservices recentSearchStrings];
    [self.tableView reloadData];
}

- (void)clearRecentsPressed:(id)sender
{
    [MITLibrariesWebservices clearRecentSearches];
    [self updateRecentSearchStrings];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.recentSearchStrings.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITLibrariesRecentsCell];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITLibrariesRecentsCell];
    }
    
    cell.textLabel.text = self.recentSearchStrings[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.delegate recentSearchesDidSelectSearchTerm:self.recentSearchStrings[indexPath.row]];
}

@end
