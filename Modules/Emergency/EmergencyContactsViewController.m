#import "EmergencyContactsViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MultiLineTableViewCell.h"
#import "UIKit+MITAdditions.h"
#import "EmergencyData.h"
#import "MIT_MobileAppDelegate+ModuleList.h"
#import "MITModule.h"

@interface EmergencyContactsViewController(Private)

- (NSString *) mainText: (id)contactInfo;
- (NSString *) detailText: (id)contactInfo;

@end

@implementation EmergencyContactsViewController

@synthesize emergencyContacts;

- (void)viewDidLoad {
    [super viewDidLoad];
    [MultiLineTableViewCell setNeedsRedrawing:YES];
}

- (void)viewWillAppear:(BOOL)animated {
	self.emergencyContacts = [[EmergencyData sharedData] allPhoneNumbers];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactsDidLoad:) name:EmergencyContactsDidLoadNotification object:nil];
    
    if (!self.emergencyContacts) {
        [[EmergencyData sharedData] reloadContacts];
    }
	
	[MIT_MobileAppDelegate moduleForTag:EmergencyTag].currentPath = @"contacts";
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EmergencyContactsDidLoadNotification object:nil];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc {
    self.emergencyContacts = nil;
    [super dealloc];
}

- (void)contactsDidLoad:(NSNotification *)aNotification {
    self.emergencyContacts = [[EmergencyData sharedData] allPhoneNumbers];
    [self.tableView reloadData];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.emergencyContacts count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {    
	NSManagedObject *contactInfo = [self.emergencyContacts objectAtIndex:indexPath.row];
    return [MultiLineTableViewCell cellHeightForTableView:tableView
                                                     text:[self mainText:contactInfo] 
                                               detailText:[self detailText:contactInfo] 
                                            accessoryType:UITableViewCellAccessoryDetailDisclosureButton];
    
    /*
	return [MultiLineTableViewCell
			cellHeightForTableView:tableView
			main:[self mainText:contactInfo]
			detail:[self detailText:contactInfo]
			widthAdjustment: 26];	
    */
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    MultiLineTableViewCell *cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        UIImageView *imageView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
        cell.accessoryView = imageView;
		[cell applyStandardFonts];
    }

	NSDictionary *contactInfo = [self.emergencyContacts objectAtIndex:indexPath.row];
	cell.textLabel.text = [self mainText:contactInfo];
	cell.detailTextLabel.text = [self detailText:contactInfo];
    return cell;
}

- (NSString *) mainText: (id)contactInfo {
	return [contactInfo valueForKey:@"title"];
}

- (NSString *) detailText: (id)contactInfo {
	NSString *phoneString = [contactInfo valueForKey:@"phone"];
	phoneString = [NSString stringWithFormat:@"(%@.%@.%@)", 
				   [phoneString substringToIndex:3], 
				   [phoneString substringWithRange:NSMakeRange(3, 3)], 
				   [phoneString substringFromIndex:6]];
	
    NSString *descriptionString = [contactInfo valueForKey:@"summary"];
    
	if (descriptionString && [descriptionString length] > 0) {
		return [NSString stringWithFormat:@"%@ %@", descriptionString, phoneString];
	} else {
		return phoneString;
	}
}
	

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSDictionary *contactInfo = [self.emergencyContacts objectAtIndex:indexPath.row];
	
	// phone numbers that aren't purely numbers should be converted
	NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", [contactInfo valueForKey:@"phone"]]];
	if ([[UIApplication sharedApplication] canOpenURL:phoneURL])
		[[UIApplication sharedApplication] openURL:phoneURL];

}




@end

