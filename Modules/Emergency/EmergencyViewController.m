#import "EmergencyModule.h"
#import "EmergencyViewController.h"
#import "EmergencyContactsViewController.h"
#import "SecondaryGroupedTableViewCell.h"
#import "MITUIConstants.h"
#import "EmergencyData.h"
#import "MITJSON.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"

@implementation EmergencyViewController

@synthesize delegate, htmlString, infoWebView;

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
		refreshButtonPressed = NO;
        infoWebView = nil;
        self.title = @"Emergency Info";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshInfo:)] autorelease];
	
	infoWebView = [[UIWebView alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20 - 20, 32)];
	infoWebView.delegate = self;
	infoWebView.dataDetectorTypes = UIDataDetectorTypeAll;
	infoWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	htmlFormatString = [@"<html>"
						"<head>"
						"<style type=\"text/css\" media=\"screen\">"
						"body { margin: 0; padding: 0; font-family: Helvetica; font-size: 17px; } "
						"</style>"
						"</head>"
						"<body>"
						"%@"
						"</body>"
						"</html>" retain];
	
	self.htmlString = [NSString stringWithFormat:htmlFormatString, @"Loading..."];
    
	[self.tableView applyStandardColors];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // register for emergencydata notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(infoDidLoad:) name:EmergencyInfoDidLoadNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(infoDidFailToLoad:) name:EmergencyInfoDidFailToLoadNotification object:nil];
    
	if ([[[EmergencyData sharedData] lastUpdated] compare:[NSDate distantPast]] == NSOrderedDescending) {
		[self infoDidLoad:nil];
	}
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[EmergencyData sharedData] setLastRead:[NSDate date]];
	EmergencyModule *emergencyModule = (EmergencyModule *)[MIT_MobileAppDelegate moduleForTag:EmergencyTag];
	[emergencyModule syncUnreadNotifications];
	[emergencyModule resetURL];
}

/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)refreshInfo:(id)sender {
	refreshButtonPressed = (sender != nil);
    [[EmergencyData sharedData] checkForEmergencies];
}

- (void)infoDidLoad:(NSNotification *)aNotification {
	refreshButtonPressed = NO;
    self.htmlString = [[EmergencyData sharedData] htmlString];
    [self.infoWebView loadHTMLString:self.htmlString baseURL:nil];
    if (self.navigationController.visibleViewController == self) {
        [[EmergencyData sharedData] setLastRead:[NSDate date]];
        EmergencyModule *emergencyModule = (EmergencyModule *)[MIT_MobileAppDelegate moduleForTag:EmergencyTag];
        [emergencyModule syncUnreadNotifications];
    }
}

- (void)infoDidFailToLoad:(NSNotification *)aNotification {
	if ([[EmergencyData sharedData] hasNeverLoaded]) {
		// Since emergency has never loaded successfully report failure
		self.htmlString = [NSString stringWithFormat:htmlFormatString, @"Failed to load notice."];
		[self.infoWebView loadHTMLString:self.htmlString baseURL:nil];
	}
	
	if (refreshButtonPressed) {
		UIAlertView *alertView = [[UIAlertView alloc] 
			initWithTitle:@"Connection Failed" 
			message:@"Failed to load notice from server." 
			delegate:nil 
			cancelButtonTitle:@"OK" 
			otherButtonTitles:nil];
		[alertView show];
		[alertView release];
	}
	
	// touch handled
	refreshButtonPressed = NO;
}
	
#pragma mark -
#pragma mark UIWebView delegation

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	if ([[EmergencyData sharedData] hasNeverLoaded]) {
		// do not recalulate the size for placeholder text
		[self.tableView reloadData];
		return;
	}
	
    if (webView == infoWebView) {
        NSString *output = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"something_unique\").offsetHeight;"];
        CGRect frame = webView.frame;
        frame.size.height = [output integerValue] + 15; // + 15 or else the web view gets its own scrollbar
        webView.frame = frame;
        [self.tableView reloadData];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    UIApplication *app = [UIApplication sharedApplication];
    NSURL *url = [request URL];
    if ([app canOpenURL:url]) {
        [app openURL:url];
    } else if ([[[request URL] absoluteString] isEqualToString:@"about:blank"]) {
        return YES;
    }
    return NO;
}
#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger num = 0;

    switch (section) {
        case 0:
            num = 1;
            break;
        case 1: {
            NSArray *numbers = [[EmergencyData sharedData] primaryPhoneNumbers];
            if (numbers) {
                num = [numbers count];
                num++; // for More Emergency Contacts drilldown
            }
            break;
        }
    }
    return num;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat rowHeight = 0;
    UIFont *cellFont = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
    CGSize constraintSize = CGSizeMake(270.0f, 2009.0f);
    NSString *cellText = nil;
    
    switch (indexPath.section) {
        case 0:
            rowHeight = infoWebView.frame.size.height + 10.0;
            break;
        default:
            cellText = @"A"; // just something to guarantee one line
            CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
            rowHeight = labelSize.height + 20.0f;
            rowHeight = MAX(44.0, rowHeight);
            break;
    }
    
    return rowHeight;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    static NSString *SecondaryCellIdentifier = @"SecondaryCell";
    
    switch (indexPath.section) {
        // Emergency Info
        case 0:
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                // info cell should not be tappable
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
            // use a UIWebView for html content
            UIWebView *existingWebView = (UIWebView *)[cell.contentView viewWithTag:42];
            if (!existingWebView) {
                existingWebView = [[UIWebView alloc] initWithFrame:infoWebView.frame];
                existingWebView.delegate = self;
                existingWebView.tag = 42;
                infoWebView.dataDetectorTypes = UIDataDetectorTypeAll;
                [cell.contentView addSubview:existingWebView];
                [existingWebView release];
            }
            existingWebView.frame = infoWebView.frame;
            [existingWebView loadHTMLString:htmlString baseURL:nil];
            existingWebView.backgroundColor = [UIColor clearColor];
            existingWebView.opaque = NO;
			return cell;
		}
        // Emergency numbers
        case 1:
		{
			SecondaryGroupedTableViewCell *cell = (SecondaryGroupedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:SecondaryCellIdentifier];
			if (cell == nil) {
				cell = [[[SecondaryGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SecondaryCellIdentifier] autorelease];
			}
			
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
            NSArray *numbers = [[EmergencyData sharedData] primaryPhoneNumbers];
            if (indexPath.row < [numbers count]) {
                NSDictionary *anEntry = [numbers objectAtIndex:indexPath.row];
				cell.textLabel.text = [anEntry objectForKey:@"title"];
				cell.secondaryTextLabel.text = [anEntry objectForKey:@"phone"];
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
            } else {
                cell.textLabel.text = @"More Emergency Contacts";
            }
			
			return cell;
		}
    }
	
	return nil;
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
    NSDictionary *anEntry;
    NSString *phoneNumber;
    NSURL *aURL;
    switch (indexPath.section) {
        case 1: {
            NSArray *numbers = [[EmergencyData sharedData] primaryPhoneNumbers];
            if (indexPath.row < [numbers count]) {
                anEntry = [numbers objectAtIndex:indexPath.row];
                phoneNumber = [[anEntry objectForKey:@"phone"] 
                               stringByReplacingOccurrencesOfString:@"." 
                               withString:@""];
                aURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneNumber]];
                if ([[UIApplication sharedApplication] canOpenURL:aURL]) {
                    [[UIApplication sharedApplication] openURL:aURL];
                }
            } else {
                // show More Emergency Contact drilldown
                // init its view controller
                EmergencyContactsViewController *contactsVC = [[EmergencyContactsViewController alloc] initWithNibName:nil bundle:nil];
                // push it onto the navigation stack
                [self.navigationController pushViewController:contactsVC animated:YES];
                [contactsVC release];
            }
            break;
        }
    }
    
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return nil;
    }
    return indexPath;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[htmlFormatString release];
	self.htmlString = nil;
	self.infoWebView = nil;
    [super dealloc];
}


@end

