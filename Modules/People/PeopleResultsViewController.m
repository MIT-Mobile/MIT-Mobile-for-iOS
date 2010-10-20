#import "PeopleResultsViewController.h"
#import "PeopleDetailsViewController.h"
#import "CoreDataManager.h"
#import "PersonDetails.h"
#import "PartialHighlightTableViewCell.h"

@implementation PeopleResultsViewController
 
- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Search Results";	
}


-(void)didReceiveMemoryWarning{

	[super didReceiveMemoryWarning];

}


- (void)dealloc {
    [super dealloc];
}


# pragma mark Table view data source methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
	
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
    return [self.searchResults count];

}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSInteger row = indexPath.row;
    
    NSString *cellID = @"Cell"; // we only have one type of cell	
    PartialHighlightTableViewCell *cell = (PartialHighlightTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
	if (cell == nil) {
        cell = [[[PartialHighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID] autorelease];
	}

	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

	NSDictionary *searchResult = [self.searchResults objectAtIndex:row];
	NSString *fullname = [[searchResult objectForKey:@"name"] objectAtIndex:0];
	
	// figure out which field (if any) to display as subtitle
	NSArray *attributes = [searchResult allKeys];
	NSArray *displayPriority = [NSArray arrayWithObjects:@"title", @"dept", nil];
	cell.detailTextLabel.text = @" "; // if this is empty textlabel will be bottom aligned
	for (NSString *tag in displayPriority) {
		if ([attributes containsObject:tag]) {
			cell.detailTextLabel.text = [[searchResult objectForKey:tag] objectAtIndex:0];
			break;
		}
	}
	
	
	// in this section we try to highlight the parts of the results that match the search terms
	
	NSMutableArray *tokens = [NSMutableArray arrayWithArray:[self.searchTerms componentsSeparatedByString:@" "]];	
	NSArray *oldTokens = [fullname componentsSeparatedByString:@" "];
	
	// temporarily place "normal[bold] [bold]normal" as textlabel
	// PartialHightlightTableViewCell will change bracketed text to bold text
	NSMutableString *preformatString = [NSMutableString stringWithCapacity:[fullname length]];
	for (NSString *oldToken in oldTokens) {
		NSArray *tokenParts = nil; // always create array so that bold string is at index 1
		NSInteger position = 0;
		NSInteger matchedPosition = 0;
		for (NSString *token in tokens) {
			// if multiple tokens match, use the longest one
			if ((tokenParts == nil) || ([token length] > [[tokenParts objectAtIndex:0] length])) {
				if ([[oldToken lowercaseString] hasPrefix:[token lowercaseString]]) {
					NSInteger length = [token length];
					tokenParts = [NSArray arrayWithObjects:@"", [oldToken substringToIndex:length], [oldToken substringFromIndex:length], nil];
					matchedPosition = position;
				} else if ([[oldToken lowercaseString] hasSuffix:[token lowercaseString]]) {
					NSInteger length = [oldToken length] - [token length];
					tokenParts = [NSArray arrayWithObjects:[oldToken substringToIndex:length], [oldToken substringFromIndex:length], nil];
					matchedPosition = position;
				}
			}
			position++;
		}
		if (tokenParts != nil) {
			[tokens removeObjectAtIndex:matchedPosition];
			[preformatString appendString:[NSString stringWithFormat:@"%@[%@]", [tokenParts objectAtIndex:0], [tokenParts objectAtIndex:1]]];
			if ([tokenParts count] == 3)
				[preformatString appendString:[tokenParts objectAtIndex:2]];			
		}
		else {
			[preformatString appendString:oldToken];
		}

		[preformatString appendString:@" "];
	}
	cell.textLabel.text = preformatString;
	
	// end of highlighting section
	
	return cell;
}

#pragma mark Table view delegate methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = [NSString stringWithFormat:@"%d results found", [self.searchResults count]];
    return title;
}

// push detail view for selected person
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSInteger array_index = indexPath.row;
	PersonDetails *personDetails;

	NSDictionary *selectedResult = [self.searchResults objectAtIndex:array_index];
	personDetails = [PersonDetails retrieveOrCreate:selectedResult];
	
	PeopleDetailsViewController *detailView = [[PeopleDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped];
	detailView.personDetails = personDetails;
	[self.navigationController pushViewController:detailView animated:YES];
	[detailView release];

}

#pragma mark Scroll view delegate methods

// clear selection if user begins dragging
// this is the default behavior but somehow our tableview or tableviewcells aren't doing it
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow]	animated:NO];
}

#pragma mark Connection delegate methods

- (void)handleData:(NSData *)data {
    [super handleData:data];
	
	[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
}

@end





