#import "MITDiningHouseVenueListViewController.h"
#import "MITDiningVenueCell.h"
#import "MITCoreData.h"
#import "MITAdditions.h"

static NSString *const kMITDiningVenueCell = @"MITDiningVenueCell";

@interface MITDiningHouseVenueListViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSArray *houseVenues;

@end

@implementation MITDiningHouseVenueListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    [self setupTableView];
    [self setupFetchedResultsController];

    [self fetchVenues];
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
    return self.houseVenues.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITDiningHouseVenue *venue = self.houseVenues[indexPath.row];
    return [MITDiningVenueCell heightForHouseVenue:venue tableViewWidth:self.view.frame.size.width];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITDiningVenueCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITDiningVenueCell forIndexPath:indexPath];
    
    [cell setHouseVenue:self.houseVenues[indexPath.row] withNumberPrefix:nil];
    
    return cell;
}


- (void)setupTableView
{
    UINib *cellNib = [UINib nibWithNibName:kMITDiningVenueCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITDiningVenueCell];
}


#pragma mark - Fetched Results Controller

- (void)setupFetchedResultsController
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MITDiningHouseVenue"
                                              inManagedObjectContext:[[MITCoreDataController defaultController] mainQueueContext]];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"shortName"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    NSFetchedResultsController *fetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:[[MITCoreDataController defaultController] mainQueueContext]
                                          sectionNameKeyPath:nil
                                                   cacheName:nil];
    self.fetchedResultsController = fetchedResultsController;
    _fetchedResultsController.delegate = self;
}

- (void)fetchVenues
{
    [self.fetchedResultsController performFetch:nil];
    self.houseVenues =  self.fetchedResultsController.fetchedObjects;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@"context changed");
}

@end
