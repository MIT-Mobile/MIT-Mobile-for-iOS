#import "MITFetchedResultsTableViewController.h"
#import "MITCoreData.h"

@interface MITFetchedResultsTableViewController ()
@property (nonatomic,strong) NSFetchedResultsController *fetchedResultsController;
@end

@implementation MITFetchedResultsTableViewController
- (id)initWithFetchRequest:(NSFetchRequest *)fetchRequest
{
    self = [self initWithStyle:UITableViewStylePlain];
    if (self) {
        _fetchRequest = fetchRequest;
    }

    return self;
}

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

    self.updateTableOnResultsChange = YES;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];

    if (error) {
        DDLogError(@"Fetch for entity name '%@' failed: %@",[self.fetchRequest entityName], error);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Lazy Fetch Controller impl.
- (NSFetchedResultsController*)fetchedResultsController
{
    if (!_fetchedResultsController) {
        if (self.fetchRequest) {
            [self loadFetchedResultsController];
        }
    }

    return _fetchedResultsController;
}

- (void)loadFetchedResultsController
{
    NSManagedObjectContext *context = [[[MIT_MobileAppDelegate applicationDelegate] coreDataController] mainQueueContext];
    if (self.managedObjectContext) {
        context = self.managedObjectContext;
    }

    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                                                 managedObjectContext:context
                                                                                   sectionNameKeyPath:nil
                                                                                            cacheName:nil];
    controller.delegate = self;

    NSError *error = nil;
    [controller performFetch:&error];

    if (error) {
        DDLogError(@"Failed to execute fetch %@: %@",self.fetchRequest,error);
        self->_fetchedResultsController = nil;
    } else {
        self->_fetchedResultsController = controller;
    }
}

- (void)setFetchRequest:(NSFetchRequest *)fetchRequest
{
    if (![self.fetchRequest isEqual:fetchRequest]) {
        _fetchRequest = fetchRequest;

        // Nil out the fetchedResultController so it will be
        // re-created for the performFetch:
        self.fetchedResultsController = nil;
        [self.tableView reloadData];
    }
}


- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    /* Does nothing by default */
}

#pragma mark - Delegate Methods
#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sections = [self.fetchedResultsController sections];
    if ([sections count]) {
        id<NSFetchedResultsSectionInfo> sectionInfo = sections[section];
        return [sectionInfo numberOfObjects];
    } else {
        return nil;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *sections = [self.fetchedResultsController sections];
    if ([sections count]) {
        id<NSFetchedResultsSectionInfo> sectionInfo = sections[section];
        return [sectionInfo name];
    } else {
        return nil;
    }
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [self.fetchedResultsController sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}


#pragma mark NSFetchedResultsController
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if (self.shouldUpdateTableOnResultsChange) {
        [self.tableView beginUpdates];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    if (self.shouldUpdateTableOnResultsChange) {
        switch(type) {
            case NSFetchedResultsChangeInsert:
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                              withRowAnimation:UITableViewRowAnimationFade];
                break;

            case NSFetchedResultsChangeDelete:
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                              withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    if (self.shouldUpdateTableOnResultsChange) {
        UITableView *tableView = self.tableView;

        switch(type) {
            case NSFetchedResultsChangeInsert:
                [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
                break;

            case NSFetchedResultsChangeDelete:
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
                break;

            case NSFetchedResultsChangeUpdate:
                [self configureCell:[tableView cellForRowAtIndexPath:indexPath]
                        atIndexPath:indexPath];
                break;

            case NSFetchedResultsChangeMove:
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
                [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (self.shouldUpdateTableOnResultsChange) {
        [self.tableView endUpdates];
    }
}
@end
