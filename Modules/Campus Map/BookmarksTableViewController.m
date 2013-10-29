#import "BookmarksTableViewController.h"
#import "CampusMapViewController.h"
#import "MITUIConstants.h"
#import "MITMapModel.h"
#import "MITCoreDataController.h"

typedef void (^MITMapBookmarksSelectionHandler)(NSOrderedSet *selectedPlaces);

@interface BookmarksTableViewController () <NSFetchedResultsControllerDelegate>
@property (nonatomic,copy) MITMapBookmarksSelectionHandler selectionBlock;
@end

@implementation BookmarksTableViewController

#pragma mark - View lifecycle
- (id)init:(void (^)(NSOrderedSet* selectedPlaces))placesSelected
{
    self = [super initWithStyle:UITableViewStylePlain];
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

    __weak BookmarksTableViewController *weakSelf = self;
    [[MITMapModelController sharedController] bookmarkedPlaces:^(NSOrderedSet *places, NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
        BookmarksTableViewController *blockSelf = weakSelf;

        if (blockSelf) {
            self.fetchRequest = fetchRequest;
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

#pragma mark - Delegate Protocols
#pragma mark UITableViewDataSource
// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.detailTextLabel.textColor = CELL_DETAIL_FONT_COLOR;
		cell.detailTextLabel.font = [UIFont systemFontOfSize:CELL_DETAIL_FONT_SIZE];
		cell.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
		cell.textLabel.font = [UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE];
    }

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	MITMapPlace* bookmarkedPlace = (MITMapPlace*)[self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [bookmarkedPlace title];
    cell.detailTextLabel.text = [bookmarkedPlace subtitle];
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        MITMapPlace* place = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [[MITMapModelController sharedController] removeBookmarkForPlace:place];
    }
}


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    MITMapPlace* place = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];
    [[MITMapModelController sharedController] moveBookmarkForPlace:place toIndex:toIndexPath.row];
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

    if (self.selectionBlock) {
        self.selectionBlock([NSOrderedSet orderedSetWithObject:place]);
    }
}

@end
