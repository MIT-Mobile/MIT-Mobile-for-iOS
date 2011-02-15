#import "BookmarksTableViewController.h"
#import "MapBookmarkManager.h"
#import "MITMapSearchResultAnnotation.h"
#import "CampusMapViewController.h"
#import "MITUIConstants.h"
#import "MapSelectionController.h"

@implementation BookmarksTableViewController

@synthesize mapSelectionController = _mapSelectionController;

#pragma mark -
#pragma mark View lifecycle

-(id) initWithMapSelectionController:(MapSelectionController*)mapSelectionController
{
	self = [super init];
	if (self) {
		self.mapSelectionController = mapSelectionController;
	}
	
	return self;

}

- (void)viewDidLoad {
    [super viewDidLoad];

		self.hidesBottomBarWhenPushed = YES;
	
	self.navigationItem.rightBarButtonItem = self.mapSelectionController.cancelButton;
    
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	
	if ([[[MapBookmarkManager defaultManager] bookmarks] count] <= 0) {
		self.editButtonItem.enabled = NO;
	}


	[self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
	self.title = @"Bookmarks";

	
	[self setToolbarItems:self.mapSelectionController.toolbarButtonItems];
}



#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[MapBookmarkManager defaultManager] bookmarks] count];	
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.detailTextLabel.textColor = CELL_DETAIL_FONT_COLOR;
		cell.detailTextLabel.font = [UIFont systemFontOfSize:CELL_DETAIL_FONT_SIZE];
		cell.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
		cell.textLabel.font = [UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE];
    }
    
	NSDictionary* bookmark = [[[MapBookmarkManager defaultManager] bookmarks] objectAtIndex:indexPath.row];
	cell.textLabel.text = [bookmark objectForKey:@"title"];
	cell.detailTextLabel.text = [bookmark objectForKey:@"subtitle"];
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
		// Delete the row from the data source
		NSDictionary* bookmark = [[[MapBookmarkManager defaultManager] bookmarks] objectAtIndex:indexPath.row];
		[[MapBookmarkManager defaultManager] removeBookmark:[bookmark objectForKey:@"id"]];
		 
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		
		if([[[MapBookmarkManager defaultManager] bookmarks] count] <= 0)
		{
			// turn off edit mode
			[self.tableView setEditing:NO animated:YES];
			self.editButtonItem.enabled = NO;
		}
		
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}




// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath 
{
	int fromRow = [fromIndexPath row];
	int toRow = [toIndexPath row];
	
	[[MapBookmarkManager defaultManager] moveBookmarkFromRow:fromRow toRow:toRow];
	
}




// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	return cell.frame.size.height + 10;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	// get the bookmark that was selected. 
	
	NSDictionary* bookmark = [[[MapBookmarkManager defaultManager] bookmarks] objectAtIndex:indexPath.row];
	
	NSDictionary* data = [bookmark objectForKey:@"data"];
	MITMapSearchResultAnnotation* annotation = [[[MITMapSearchResultAnnotation alloc] initWithInfo:data] autorelease];
	annotation.bookmark = YES;
	
	[_mapSelectionController.mapVC.mapView removeAnnotations:_mapSelectionController.mapVC.mapView.annotations];
	[_mapSelectionController.mapVC.mapView addAnnotation:annotation];
	[_mapSelectionController.mapVC.mapView selectAnnotation:annotation];
	
	[_mapSelectionController.mapVC pushAnnotationDetails:annotation animated:NO];
	
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

