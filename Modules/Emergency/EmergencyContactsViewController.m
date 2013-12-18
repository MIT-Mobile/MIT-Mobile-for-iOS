#import "EmergencyContactsViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MultiLineTableViewCell.h"
#import "MITMultilineTableViewCell.h"
#import "UIKit+MITAdditions.h"
#import "EmergencyData.h"
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
    static UITableViewCell *templateCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        templateCell = [self tableView:nil cellForRowAtIndexPath:indexPath];
    });

    [self configureCell:templateCell
            atIndexPath:indexPath
           forTableView:tableView];
    
    // Get the cells ideal size for its content.
    CGSize cellSize = [templateCell sizeThatFits:CGSizeMake(CGRectGetWidth(tableView.bounds), CGFLOAT_MAX)];
    return cellSize.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    MITMultilineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[MITMultilineTableViewCell alloc] init];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
    }
    
    [self configureCell:cell
            atIndexPath:indexPath
           forTableView:tableView];

    return cell;
}

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath forTableView:(UITableView*)tableView
{
    MITMultilineTableViewCell *multilineCell = (MITMultilineTableViewCell*)cell;

	NSManagedObject *contactInfo = self.emergencyContacts[indexPath.row];
	multilineCell.headlineLabel.text = [contactInfo valueForKey:@"title"];
	multilineCell.bodyLabel.text = [self detailText:contactInfo];
}

- (NSString *)detailText:(NSManagedObject*)contactInfo {
	NSString *phoneString = [contactInfo valueForKey:@"phone"];
	phoneString = [NSString stringWithFormat:@"(%@.%@.%@)", 
				   [phoneString substringToIndex:3], 
				   [phoneString substringWithRange:NSMakeRange(3, 3)], 
				   [phoneString substringFromIndex:6]];
	
    NSString *descriptionString = [contactInfo valueForKey:@"summary"];
    
	if ([descriptionString length]) {
		return [NSString stringWithFormat:@"%@ %@", descriptionString, phoneString];
	} else {
		return phoneString;
	}
}
	

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSDictionary *contactInfo = [self.emergencyContacts objectAtIndex:indexPath.row];
	
	// phone numbers that aren't purely numbers should be converted
	NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", [contactInfo valueForKey:@"phone"]]];
	if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
		[[UIApplication sharedApplication] openURL:phoneURL];
    }

}




@end

