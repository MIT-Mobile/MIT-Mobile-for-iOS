#import "MITMartyTypeAheadTableViewController.h"
#import "MITMapModelController.h"
#import "CoreData+MITAdditions.h"
#import "UIKit+MITAdditions.h"

@interface MITMartyTypeAheadTableViewController ()

@property (nonatomic, strong) NSString *currentSearchString;

@end

@implementation MITMartyTypeAheadTableViewController

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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark - Public Methods

- (void)updateResultsWithSearchTerm:(NSString *)searchTerm
{
    if ([searchTerm isEqualToString:@""]) {
        searchTerm = nil;
    }
    
    self.currentSearchString = searchTerm;
    
    [self showTitleHeaderIfNecessary];
    
    __weak MITMartyTypeAheadTableViewController *blockSelf = self;
    
    // The error cases in these blocks are left unhandled on purpose for now. Not sure if the user ever needs to be informed
    [[MITMapModelController sharedController] recentSearchesForPartialString:searchTerm loaded:^(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
        if (![blockSelf isCurrentSearchStringEqualTo:searchTerm]) {
            return;
        }
        if (fetchRequest) {
            NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
            [[MITCoreDataController defaultController] performBackgroundFetch:fetchRequest completion:^(NSOrderedSet *fetchedObjectIDs, NSError *error) {
                if (![blockSelf isCurrentSearchStringEqualTo:searchTerm]) {
                    return;
                }
                self.recentSearchItems = [managedObjectContext objectsWithIDs:[fetchedObjectIDs array]];
                [self.tableView reloadData];
            }];
        }
    }];
    
    [self.tableView reloadData];
}

- (BOOL)isCurrentSearchStringEqualTo:(NSString *)searchString
{
    if (searchString == nil && self.currentSearchString == nil) {
        return YES;
    } else if ([searchString isEqualToString:self.currentSearchString]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)showTitleHeaderIfNecessary
{
    if (self.showsTitleHeader) {
        if (self.currentSearchString == nil || self.currentSearchString.length < 1) {
            [super showTitleHeaderIfNecessary];
        }
    } else {
        self.tableView.tableHeaderView = nil;
    }
}

#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [super numberOfSectionsInTableView:tableView] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

@end
