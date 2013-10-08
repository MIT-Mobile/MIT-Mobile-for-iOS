#import "BookmarksTableViewController.h"
#import "MapBookmarkManager.h"
#import "MITMapSearchResultAnnotation.h"
#import "CampusMapViewController.h"
#import "MITUIConstants.h"
#import "MITMapPlace.h"


typedef void (^MITMapBookmarksSelectionHandler)(NSOrderedSet *selectedPlaces);

@interface BookmarksTableViewController ()
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
	if (![[[MapBookmarkManager defaultManager] bookmarks] count]) {
		self.editButtonItem.enabled = NO;
	}

    [self.navigationItem setLeftBarButtonItem:self.editButtonItem animated:animated];

    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                              target:self
                                                                              action:@selector(doneButtonPressed:)];
	[self.navigationItem setRightBarButtonItem:doneItem animated:animated];
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
}

#pragma mark -
#pragma mark Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[MapBookmarkManager defaultManager] bookmarks] count];
}


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

    NSArray *bookmarks = [[MapBookmarkManager defaultManager] bookmarks];
	MITMapPlace* bookmark = bookmarks[indexPath.row];

    if ([bookmark.buildingNumber length]) {
        cell.textLabel.text = [NSString stringWithFormat:@"Building %@", bookmark.buildingNumber];

        if (![cell.textLabel.text isEqualToString:bookmark.name]) {
            cell.detailTextLabel.text = bookmark.name;
        }
    } else {
        cell.textLabel.text = bookmark.name;
    }

    return cell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		// Delete the row from the data source
        NSArray *bookmarks = [[MapBookmarkManager defaultManager] bookmarks];
        MITMapPlace* bookmark = bookmarks[indexPath.row];
		[[MapBookmarkManager defaultManager] removeBookmark:bookmark];

        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];

		if(![bookmarks count]) {
			// turn off edit mode
			[self.tableView setEditing:NO animated:YES];
			self.editButtonItem.enabled = NO;
		}
    }
}


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
	[[MapBookmarkManager defaultManager] moveBookmarkFromRow:fromIndexPath.row
                                                       toRow:toIndexPath.row];
}


// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}

#pragma mark - Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	return cell.frame.size.height + 10;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	// get the bookmark that was selected.

    NSArray *bookmarks = [[MapBookmarkManager defaultManager] bookmarks];
    MITMapPlace* bookmark = bookmarks[indexPath.row];

    if (self.selectionBlock) {
        self.selectionBlock([NSOrderedSet orderedSetWithObject:bookmark]);
    }
}

@end
