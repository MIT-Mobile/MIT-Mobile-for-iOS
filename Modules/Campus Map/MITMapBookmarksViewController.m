#import "MITMapBookmarksViewController.h"
#import "CampusMapViewController.h"
#import "MITUIConstants.h"
#import "MITMapModel.h"
#import "MITCoreDataController.h"

typedef void (^MITMapBookmarksSelectionHandler)(NSOrderedSet *mapPlaceIDs);

@interface MITMapBookmarksViewController ()
@property (nonatomic,copy) MITMapBookmarksSelectionHandler selectionBlock;

- (void)didCompleteSelectionWithPlaces:(NSOrderedSet*)mapPlaces;
@end

@implementation MITMapBookmarksViewController

#pragma mark - View lifecycle
- (id)init:(void (^)(NSOrderedSet* mapPlaceIDs))placesSelected
{
    self = [super initWithFetchRequest:nil];
    if (self) {
	    self.title = @"Bookmarks";
        self.selectionBlock = placesSelected;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

	if ([[MITMapModelController sharedController] numberOfBookmarks]) {
		self.editButtonItem.enabled = YES;
	}

    [self.navigationItem setLeftBarButtonItem:self.editButtonItem animated:animated];

    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                              target:self
                                                                              action:@selector(doneButtonPressed:)];
	[self.navigationItem setRightBarButtonItem:doneItem animated:animated];

    __weak MITMapBookmarksViewController *weakSelf = self;
    self.fetchRequest = [[MITMapModelController sharedController] bookmarkedPlaces:^(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
        MITMapBookmarksViewController *blockSelf = weakSelf;

        if (blockSelf) {
            [blockSelf.tableView reloadData];
        }
    }];
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

- (IBAction)doneButtonPressed:(UIBarButtonItem*)doneItem
{
    if (self.selectionBlock) {
        self.selectionBlock(nil);
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    if (editing) {
        [self.navigationItem setRightBarButtonItem:nil animated:animated];
    } else {
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                  target:self
                                                                                  action:@selector(doneButtonPressed:)];
        [self.navigationItem setRightBarButtonItem:doneItem animated:animated];
    }
}


- (void)didCompleteSelectionWithPlaces:(NSOrderedSet*)mapPlaces
{
    if (self.selectionBlock) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.selectionBlock(mapPlaces);
        }];
    }
}

#pragma mark - Delegate Protocols
#pragma mark UITableViewDataSource
// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

	MITMapPlace* bookmarkedPlace = (MITMapPlace*)[self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [bookmarkedPlace title];
    cell.detailTextLabel.text = [bookmarkedPlace subtitle];

    return cell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        MITMapPlace* place = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [[MITMapModelController sharedController] removeBookmarkForPlace:place completion:nil];
    }
}


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    MITMapPlace* place = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];
    [[MITMapModelController sharedController] moveBookmarkForPlace:place toIndex:toIndexPath.row completion:nil];
}


// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	// get the bookmark that was selected.
    MITMapPlace* place = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self didCompleteSelectionWithPlaces:[NSOrderedSet orderedSetWithObject:[place objectID]]];
}

@end
