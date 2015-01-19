#import "MITFetchedResultsTableViewController.h"
#import "MITCoreData.h"

@interface MITFetchedResultsTableViewController ()
@property (nonatomic,strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation MITFetchedResultsTableViewController
- (instancetype)init
{
    return [self initWithFetchRequest:nil];
}

- (instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest
{
    self = [super init];
    if (self) {
        _fetchRequest = [fetchRequest copy];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    
    if (error) {
        DDLogWarn(@"[%@] FRC fetch failed: %@", NSStringFromClass([self class]),error);
    } else {
        [self.tableView reloadData];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Properties
#pragma mark Accessors/Loading
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
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                                                 managedObjectContext:self.managedObjectContext
                                                                                   sectionNameKeyPath:nil
                                                                                            cacheName:nil];
    controller.delegate = self;
    _fetchedResultsController = controller;
}

#pragma mark Mutators
- (void)setFetchRequest:(NSFetchRequest *)fetchRequest
{
    if (![self.fetchRequest isEqual:fetchRequest]) {
        _fetchRequest = fetchRequest;

        self.fetchedResultsController = nil;
    }
}

- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        DDLogWarn(@"[%@] A managed object context was not assigned before being added to the view hierarchy. The default main queue managed object context will be used",self);
        _managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
    }
    
    return _managedObjectContext;
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
                [tableView reloadRowsAtIndexPaths:@[indexPath]
                                 withRowAnimation:UITableViewRowAnimationNone];
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
