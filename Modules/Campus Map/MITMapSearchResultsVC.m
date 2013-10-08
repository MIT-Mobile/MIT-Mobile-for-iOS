#import "MITMapSearchResultsVC.h"
#import "MITMapSearchResultAnnotation.h"
#import "MITMapDetailViewController.h"
#import "CampusMapViewController.h"
#import "TouchableTableView.h"
#import "MITUIConstants.h"
#import "MultiLineTableViewCell.h"
#import "MITMapPlace.h"

@interface MITMapSearchResultsVC ()
@property (nonatomic,weak) IBOutlet UITableView* tableView;
@end

@implementation MITMapSearchResultsVC
- (void)viewDidUnload {
	self.searchResults = nil;
	[super viewDidUnload];
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

-(void) setSearchResults:(NSArray *)searchResults
{
	_searchResults = searchResults;
}

-(void) touchEnded
{
	[self.campusMapVC.searchBar resignFirstResponder];
}
#pragma mark Table view methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.searchResults count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString* CellIdentifier = @"Cell";
	
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
	// get the annotation for this index
	MITMapSearchResultAnnotation* annotation = self.searchResults[indexPath.row];
	cell.textLabel.text = annotation.place.name;
	
	if(nil != annotation.place.buildingNumber)
		cell.detailTextLabel.text = [NSString stringWithFormat:@"Building %@", annotation.place.buildingNumber];
	else
		cell.detailTextLabel.text = nil;
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	MITMapDetailViewController* detailsVC = [[MITMapDetailViewController alloc] initWithNibName:@"MITMapDetailViewController"
																						  bundle:nil];
	
	MITMapSearchResultAnnotation* annotation = self.searchResults[indexPath.row];
	detailsVC.place = annotation.place;
	detailsVC.title = @"Info";
	detailsVC.campusMapVC = self.campusMapVC;

	if (self.isCategory) {
		detailsVC.queryText = detailsVC.place.name;
	} else if([self.campusMapVC.lastSearchText length]) {
		detailsVC.queryText = self.campusMapVC.lastSearchText;
		[self.campusMapVC.url setPath:[NSString stringWithFormat:@"detail/%@", annotation.place.buildingNumber]
                                query:self.campusMapVC.lastSearchText];
		[self.campusMapVC.url setAsModulePath];
		[self.campusMapVC setURLPathUserLocation];
	}
	
	[self.campusMapVC.navigationController pushViewController:detailsVC animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[cell setNeedsLayout];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	MITMapSearchResultAnnotation* annotation = self.searchResults[indexPath.row];
	
	CGFloat width = self.view.frame.size.width - 33.0;
	
	CGSize labelSize = [annotation.place.name sizeWithFont:[UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE]
								   constrainedToSize:CGSizeMake(width, self.view.frame.size.height)
									   lineBreakMode:NSLineBreakByWordWrapping];
	
	CGFloat height = labelSize.height;

	NSString *detailString = [NSString stringWithFormat:@"Building %@", annotation.place.buildingNumber];
	
	labelSize = [detailString sizeWithFont:[UIFont systemFontOfSize:CELL_DETAIL_FONT_SIZE]
						 constrainedToSize:CGSizeMake(width, 200.0)
							 lineBreakMode:NSLineBreakByWordWrapping];
	
	CGFloat cellheight = round((height + labelSize.height) * 1.2 + 12.0);
	
	return cellheight;

}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *title = [NSString stringWithFormat:@"%d found", [self.searchResults count]];
	return [UITableView ungroupedSectionHeaderWithTitle:title];
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return UNGROUPED_SECTION_HEADER_HEIGHT;
}

@end

