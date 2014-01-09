#import "MITMapCategoriesViewController.h"

#import "MITAdditions.h"
#import "MITMapModel.h"
#import "MITMapPlacesViewController.h"

static NSString* const MITMapCategoryViewAllText = @"View all on map";

@interface MITMapCategoriesViewController () <MITMapCategoriesDelegate,MITMapPlaceSelectionDelegate>
@property (nonatomic,strong) MITMapCategory *category;

- (id)initWithCategory:(MITMapCategory*)category;
@end

@implementation MITMapCategoriesViewController
- (id)init
{
    return [self initWithCategory:nil];
}

- (id)initWithCategory:(MITMapCategory*)category
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[MITMapCategory entityName]];

    if (category) {
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"parent == %@",category];
    }

    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];

    self = [super initWithFetchRequest:fetchRequest];
    if (self) {
        _category = category;
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


    
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForSelectedRows] withRowAnimation:UITableViewRowAnimationNone];

    if (!self.category) {
        // We are about to appear and we will be showing
        // the list of top-level categories. Stick the 'Cancel' button
        // here
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                    target:self
                                                                                    action:@selector(cancelItemTouched:)];
        self.navigationItem.leftBarButtonItem = cancelItem;
        self.navigationItem.title = @"Browse";
    } else {
        // Make sure the category object we have is in the right mananged object context.
        // This assumes that, if an NSManagedObjectContext (other than main) is desired,
        //  it was assigned before adding the view controller to the hierarchy
        self.category = (MITMapCategory*)[self.managedObjectContext objectWithID:[self.category objectID]];

        self.navigationItem.title = self.category.name;
    }

    // Update the available categories
    [[MITMapModelController sharedController] categories:^(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
        if (!error) {
            [self.fetchedResultsController performFetch:nil];
            [self.tableView reloadData];
        } else {
            DDLogWarn(@"Failed to retreive category listing: %@",error);
        }
    }];
}

- (void)didCompleteSelectionWithObjects:(NSArray*)selection inCategory:(MITMapCategory*)category
{
    if (self.delegate) {
        if (selection) {
            [self.delegate controller:self didSelectObjects:selection inCategory:category];
        } else if (category) {
            [self.delegate controller:self didSelectCategory:category];
        } else {
            [self.delegate controllerDidCancelSelection:self];
        }
    }
}

- (IBAction)cancelItemTouched:(UIBarButtonItem*)doneItem
{
    [self didCompleteSelectionWithObjects:nil inCategory:nil];
}

#pragma mark - Table view data source
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    // Use the older dequeue method here because we are using the UITableViewCellStyleSubtitle
    // style and not providing a subclass which overrides initWithStyle:reuseIdentifier:
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    MITMapCategory *category = self.fetchedResultsController.fetchedObjects[indexPath.row];
    cell.textLabel.text = category.name;

    NSIndexPath *selectedIndexPath = [tableView indexPathForSelectedRow];
    if ([selectedIndexPath isEqual:indexPath]) {
        UIActivityIndicatorView *indicatorView = (UIActivityIndicatorView*)cell.accessoryView;

        if (!([indicatorView isKindOfClass:[UIActivityIndicatorView class]])) {
            indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            indicatorView.hidesWhenStopped = YES;

            cell.accessoryView = indicatorView;
        }

        cell.accessoryType = UITableViewCellAccessoryNone;
        [indicatorView startAnimating];
    } else {
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITMapCategory *category = self.fetchedResultsController.fetchedObjects[indexPath.row];

    if ([category.children count]) {
        MITMapCategoriesViewController *categoriesViewController = [[MITMapCategoriesViewController alloc] initWithCategory:category];
        categoriesViewController.delegate = self;

        [self.navigationController pushViewController:categoriesViewController animated:YES];
    } else {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicatorView.hidesWhenStopped = YES;
        [indicatorView startAnimating];
        cell.accessoryView = indicatorView;
        cell.accessoryType = UITableViewCellAccessoryNone;
        [cell sizeToFit];
        
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];

        __weak MITMapCategoriesViewController *weakSelf = self;
        MITMapModelController *modelController = [MITMapModelController sharedController];
        [modelController placesInCategory:category
                                   loaded:^(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
                                       MITMapCategoriesViewController *blockSelf = weakSelf;
                                       if (!error) {
                                           NSIndexPath *selectedRow = [tableView indexPathForSelectedRow];
                                           if ([selectedRow isEqual:indexPath]) {
                                               MITMapPlacesViewController *viewController = [[MITMapPlacesViewController alloc] initWithPredicate:fetchRequest.predicate
                                                                                                                                  sortDescriptors:fetchRequest.sortDescriptors];
                                               viewController.delegate = self;
                                               [blockSelf.navigationController pushViewController:viewController animated:YES];
                                           }
                                       } else {
                                           [blockSelf didCompleteSelectionWithObjects:nil inCategory:nil];
                                       }

                                       [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                                   }];
    }
}


#pragma mark MITMapCategoriesDelegate
- (void)controller:(MITMapCategoriesViewController *)controller didSelectObjects:(NSArray *)objects inCategory:(MITMapCategory *)category
{
    [self didCompleteSelectionWithObjects:objects inCategory:category];
}

- (void)controller:(MITMapCategoriesViewController *)controller didSelectCategory:(MITMapCategory *)category
{
    [self didCompleteSelectionWithObjects:nil inCategory:category];
}

- (void)controllerDidCancelSelection:(MITMapCategoriesViewController *)controller
{
    [self didCompleteSelectionWithObjects:nil inCategory:nil];
}

#pragma mark MITMapPlaceSelectionDelegate
- (void)placesController:(MITMapPlacesViewController *)controller didSelectPlaces:(NSArray *)objects
{
    [self didCompleteSelectionWithObjects:objects inCategory:self.category];
}

- (void)placesControllerDidCancelSelection:(MITMapPlacesViewController *)controller
{
    [self didCompleteSelectionWithObjects:nil inCategory:nil];
}

@end
