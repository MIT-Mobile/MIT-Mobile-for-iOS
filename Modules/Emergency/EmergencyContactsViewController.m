#import "EmergencyContactsViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MultiLineTableViewCell.h"
#import "UIKit+MITAdditions.h"
#import "EmergencyData.h"
#import "MIT_MobileAppDelegate+ModuleList.h"
#import "MITModule.h"

@interface EmergencyContactsViewController ()
- (NSString *)detailText:(NSManagedObject*)contactInfo;
@end

@implementation EmergencyContactsViewController

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

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)contactsDidLoad:(NSNotification *)aNotification {
    self.emergencyContacts = [[EmergencyData sharedData] allPhoneNumbers];
    [self.tableView reloadData];
}

#pragma mark Table view methods
// Do not delete this method. It is required by the MultiLineTableViewCell
// and will crash if it is removed.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.emergencyContacts count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {    
	NSManagedObject *contactInfo = self.emergencyContacts[indexPath.row];
    return [MultiLineTableViewCell cellHeightForTableView:tableView
                                                     text:[contactInfo valueForKey:@"title"]
                                               detailText:[self detailText:contactInfo] 
                                            accessoryType:UITableViewCellAccessoryDetailDisclosureButton];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    MultiLineTableViewCell *cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        // Required by the MultiLineTableViewCell. If the accessoryType is not set, MultiLineTableViewCell
        // will enter an infinite loop.
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        cell.accessoryView =  [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
		[cell applyStandardFonts];
    }

	NSManagedObject *contactInfo = self.emergencyContacts[indexPath.row];
	cell.textLabel.text = [contactInfo valueForKey:@"title"];
	cell.detailTextLabel.text = [self detailText:contactInfo];
    return cell;
}

- (NSString *)detailText:(NSManagedObject*)contactInfo {
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

