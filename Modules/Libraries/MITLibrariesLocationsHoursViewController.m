#import "MITLibrariesLocationsHoursViewController.h"
#import "MITLibrariesLibrary.h"
#import "MITLibrariesLibraryCell.h"
#import "MITLibrariesWebservices.h"

static NSString *const kMITLibraryCell = @"MITLibrariesLibraryCell";

@interface MITLibrariesLocationsHoursViewController ()

@property (nonatomic, strong) NSArray *libraries;

@end

@implementation MITLibrariesLocationsHoursViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupTableView];
    
    [MITLibrariesWebservices getLibrariesWithCompletion:^(NSArray *libraries, NSError *error) {
        if (libraries) {
            self.libraries = libraries;
            [self.tableView reloadData];
        }
    }];
}

- (void)setupTableView
{
    UINib *cellNib = [UINib nibWithNibName:kMITLibraryCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITLibraryCell];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.libraries.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [MITLibrariesLibraryCell heightForContent:self.libraries[indexPath.row] tableViewWidth:self.tableView.frame.size.width];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITLibrariesLibraryCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITLibraryCell];
    
    [cell setContent:self.libraries[indexPath.row]];
    
    return cell;
}

@end
