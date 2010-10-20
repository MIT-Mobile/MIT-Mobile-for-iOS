#import "PeopleRootViewController.h"
#import "PeopleResultsViewController.h"
#import "PeopleDetailsViewController.h"
#import "PeopleRecentsData.h"
#import "PersonDetails.h"
#import "MIT_MobileAppDelegate.h"

@implementation PeopleRootViewController

@synthesize recents, searchHints; //, loadingView, connection, searchResults;

- (void) phoneIconTapped
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dial 6172531000?" 
													message:@"" 
												   delegate:self
										  cancelButtonTitle:@"Cancel" 
										  otherButtonTitles:@"Dial", nil];
	[alert show];
}

- (void) dealloc
{
	[recents release];
	[searchHints release];
	[super dealloc];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.recents = [[PeopleRecentsData sharedData] recents];
	self.title = @"Directory";
	self.searchHints = @"Sample searches:\nName: 'william barton rogers', 'rogers'\nEmail: 'wbrogers', 'wbrogers@mit.edu'\nPhone: '6172531000', '31000'";
}

/*
 - (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}
*/

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if ([self.recents count] == 0)
		return 1;
    return 2;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case 0: // phone directory & emergency contacts
			return 2;
			break;
		case 1: // recently viewed
			return [self.recents count];
			break;
	}
	return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSString *cellID;
	UITableViewCellStyle style;
	if (indexPath.section == 0) {
		cellID = @"InfoCell";
		style = UITableViewCellStyleDefault;
	} else {
		cellID = @"RecentCell";
		style = UITableViewCellStyleSubtitle;
	}
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
	cell = [[[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellID] autorelease];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			cell.textLabel.text = @"Phone Directory";
			UIImage *image = [UIImage imageNamed:@"action-phone.png"];
			
			// phone accessory
			UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
			button.frame = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
			[button setBackgroundImage:image forState:UIControlStateNormal];
			[button addTarget:self action:@selector(phoneIconTapped) forControlEvents:UIControlEventTouchUpInside];
			
			cell.accessoryView = button;
		} else {
			cell.textLabel.text = @"Emergency Contacts";
		}
		
	} else { // recents
		cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
		cell.detailTextLabel.font = [UIFont systemFontOfSize:12.5f];
			
		PersonDetails *recent = [self.recents objectAtIndex:indexPath.row];
		cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", [recent valueForKey:@"givenname"], [recent valueForKey:@"surname"]];

		// show person's title, dept, or email as cell's subtitle text
		NSArray *displayPriority = [NSArray arrayWithObjects:@"title", @"dept", nil];
		NSString *displayText;
		for (NSString *tag in displayPriority) {
			if (displayText = [recent valueForKey:tag]) {
				cell.detailTextLabel.text = displayText;
				break;
			}
		}
	}
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if (section == 0) {
		CGRect bounds = [[UIScreen mainScreen] applicationFrame];
		CGSize labelSize = [self.searchHints sizeWithFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]
										constrainedToSize:bounds.size
											lineBreakMode:UILineBreakModeWordWrap];
		return labelSize.height + 20.0;
	}
	return 36.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	if (section == 1)
		return 64.0;
	else
		return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
    if (section == 1) {
		title = @"Recently Viewed";
	}
    return title;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	UIView *view = nil;
	if (section == 0) {
		CGRect bounds = [[UIScreen mainScreen] applicationFrame];
		UIFont *hintsFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
		CGSize labelSize = [self.searchHints sizeWithFont:hintsFont
										constrainedToSize:bounds.size
											lineBreakMode:UILineBreakModeWordWrap];
		
		UILabel *hintsLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 5.0f, labelSize.width, labelSize.height + 5.0)];
		hintsLabel.numberOfLines = 0;
		hintsLabel.backgroundColor = [UIColor clearColor];
		hintsLabel.lineBreakMode = UILineBreakModeWordWrap;
		hintsLabel.font = hintsFont;
		hintsLabel.text = self.searchHints;
		view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, labelSize.width, labelSize.height + 10.0)];
		[view addSubview:hintsLabel];
		
	}
	return view;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	UIView *view = nil;
	if (section == 1) {
		CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
		view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, appFrame.size.width, 64.0)];
		UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
		[button setFrame:CGRectMake(10.0, 20.0, appFrame.size.width - 20.0, 44.0)];
        button.titleLabel.text = @"Clear Recents";
		button.titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
		button.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
		button.titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.3];
		[button setTitle:@"Clear Recents" forState:UIControlStateNormal];

		// based on code from stackoverflow.com/questions/1427818/iphone-sdk-creating-a-big-red-uibutton
		[button setBackgroundImage:[[UIImage imageNamed:@"redbutton2.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] 
						  forState:UIControlStateNormal];
		[button setBackgroundImage:[[UIImage imageNamed:@"redbutton2highlighted.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] 
						  forState:UIControlStateHighlighted];
		
		[button addTarget:self action:@selector(showActionSheet) forControlEvents:UIControlEventTouchUpInside];
		[view addSubview:button];
	}
	return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			[self phoneIconTapped];
		}
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
		
	} else if (indexPath.section == 1) {
		PersonDetails *personDetails = [self.recents objectAtIndex:indexPath.row];
		PeopleDetailsViewController *detailView = [[PeopleDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped];
		detailView.personDetails = personDetails;
		[self.navigationController pushViewController:detailView animated:YES];
		[detailView release];
	}
}


#pragma mark -
#pragma mark Connection methods

- (void)handleData:(NSData *)data {
	[super handleData:data];

	if ([searchResults count] == 1) {
		NSDictionary *singleResult = [searchResults objectAtIndex:0];
		PersonDetails *personDetails = [PersonDetails retrieveOrCreate:singleResult];		
		PeopleDetailsViewController *detailView = [[PeopleDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped];
		detailView.personDetails = personDetails;
		[self.navigationController pushViewController:detailView animated:YES];
			
	} else { // this includes search results of zero count
		PeopleResultsViewController *resultsView = [[PeopleResultsViewController alloc] initWithNibName:nil bundle:nil];
		resultsView.searchResults = searchResults;
		resultsView.searchTerms = searchTerms;
		[self.navigationController pushViewController:resultsView animated:YES];
	}
}

#pragma mark Alert view delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != [alertView cancelButtonIndex]) { // user hit "Dial"
		NSURL *externURL = [NSURL URLWithString:@"tel://6172531000"];
		[[UIApplication sharedApplication] openURL:externURL];
	}
}

#pragma mark Action sheet methods

- (void)showActionSheet
{
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Clear Recents?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Clear" otherButtonTitles:nil];
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[UIApplication sharedApplication].delegate;
    [sheet showFromTabBar:appDelegate.tabBarController.tabBar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Clear"]) {
		[PeopleRecentsData eraseAll];
		[self.tableView reloadData];
		[self.tableView scrollRectToVisible:CGRectMake(0.0, 0.0, 1.0, 1.0) animated:YES];
	}
}


@end
