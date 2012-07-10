#import "PeopleDetailsViewController.h"
#import "PeopleDetailsTableViewCell.h"
#import "ConnectionDetector.h"
#import "PeopleRecentsData.h"
#import "MIT_MobileAppDelegate.h"
#import "MITUIConstants.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "MITMailComposeController.h"

@implementation PeopleDetailsViewController

@synthesize personDetails, sectionArray, fullname;

- (void)viewDidLoad
{
	self.title = @"Info";
	[self.tableView applyStandardColors];
    
    // get fullname for header
    self.fullname = [self.personDetails displayName];
	
	// populate remaining contents to be displayed
	self.sectionArray = [[[NSMutableArray alloc] init] autorelease];
	
	NSArray *jobSection = [NSArray arrayWithObjects:@"title", @"dept", nil];
	NSArray *phoneSection = [NSArray arrayWithObjects:@"phone", @"fax", nil];
	NSArray *emailSection = [NSArray arrayWithObject:@"email"];
	NSArray *officeSection = [NSArray arrayWithObject:@"office"];//, @"room", nil];
	
	NSArray *sectionCandidates = [NSArray arrayWithObjects:jobSection, emailSection, phoneSection, officeSection, nil];
	
	NSMutableArray *currentSection = nil;
	NSString *displayTag;
	NSString *ldapValue;
	
	for (NSArray *section in sectionCandidates) {
		// each element of currentSection will be a 2-array of NSString *tag and NSString *value
		currentSection = [[NSMutableArray alloc] init];
		for (NSString *ldapTag in section) {
			ldapValue = [self.personDetails valueForKey:ldapTag];
			displayTag = ldapTag;
			
			if (ldapValue != nil) {
				// create one tag/label pair for each email/phone/office label
				if ([ldapTag isEqualToString:@"email"] || 
					[ldapTag isEqualToString:@"phone"] ||
					//[ldapTag isEqualToString:@"room"] || 
					[ldapTag isEqualToString:@"office"]) {
					for (NSString *value in [ldapValue componentsSeparatedByString:@","])
						[currentSection addObject:[NSArray arrayWithObjects:ldapTag, value, nil]];
					continue;
				}
				[currentSection addObject:[NSArray arrayWithObjects:displayTag, ldapValue, nil]];
			}
		}
		
		if ([currentSection count] > 0)
			[self.sectionArray addObject:currentSection];
        [currentSection release];
	}
	
	// create header
	CGSize labelSize = [self.fullname sizeWithFont:[UIFont boldSystemFontOfSize:20.0]
								 constrainedToSize:CGSizeMake(self.tableView.frame.size.width - 20.0, 2000.0)
									 lineBreakMode:UILineBreakModeWordWrap];
	UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 10.0, labelSize.width, labelSize.height)];
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, labelSize.height + 14.0)] autorelease];
	nameLabel.text = self.fullname;
	nameLabel.numberOfLines = 0;
	nameLabel.lineBreakMode = UILineBreakModeWordWrap;
	nameLabel.font = [UIFont boldSystemFontOfSize:20.0];
	nameLabel.backgroundColor = [UIColor clearColor];
	[header addSubview:nameLabel];
	[nameLabel release];

	self.tableView.tableHeaderView = header;
	
	// if lastUpdate is sufficiently long ago, issue a background search
	// TODO: change this time interval to something more reasonable
	if ([[self.personDetails valueForKey:@"lastUpdate"] timeIntervalSinceNow] < -300) { // 5 mins for testing
		if ([ConnectionDetector isConnected]) {
			// issue this query but don't care too much if it fails
			MITMobileWebAPI *api = [MITMobileWebAPI jsonLoadedDelegate:self];
			[api requestObject:[NSDictionary dictionaryWithObjectsAndKeys:@"people", @"module", self.fullname, @"q", nil]];
		}
	}
	
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	
	[sectionArray release];
	[personDetails release];
	[fullname release];
    [super dealloc];
}

#pragma mark -
#pragma mark Connection methods + wrapper delegate

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)result {
	if (result && [result isKindOfClass:[NSArray class]]) { // fail silently
		for (NSDictionary *entry in result) {
			if ([[entry objectForKey:@"id"] isEqualToString:[self.personDetails valueForKey:@"uid"]]) {
				self.personDetails = [PeopleRecentsData updatePerson:self.personDetails withSearchResult:entry];
				[self.tableView reloadData];
			}
		}
	}
}
- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error {
	return NO;
}

/*
-(void)handleConnectionFailure
{
}
*/

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	return [self.sectionArray count] + 1;
	
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	if (section == [self.sectionArray count])
		return 2;
	return [[self.sectionArray objectAtIndex:section] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;

	NSString *cellID = [NSString stringWithFormat:@"%d",section];
	
	if (section == [self.sectionArray count]) { 
		// cells for Create New / Add Existing rows at the end
		// we are mimicking the style of UIButtonTypeRoundedRect until we find something more built-in
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
		
		if (cell == nil)
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];

		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.textLabel.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
		cell.textLabel.textColor = STANDARD_CONTENT_FONT_COLOR;
		if (row == 0)
			cell.textLabel.text = @"Create New Contact";
		else
			cell.textLabel.text = @"Add to Existing Contact";
		
		return cell;
		
	} else { // cells for displaying person details
		PeopleDetailsTableViewCell *cell = (PeopleDetailsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
		
		if (cell == nil)
			cell = [[[PeopleDetailsTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellID] autorelease];
		
		NSArray *personInfo = [[self.sectionArray objectAtIndex:section] objectAtIndex:row];
		NSString *tag = [personInfo objectAtIndex:0];
		NSString *data = [personInfo objectAtIndex:1];
		
		cell.textLabel.text = tag;
		cell.detailTextLabel.text = data;
		
		if ([tag isEqualToString:@"email"]) {
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
		} else if ([tag isEqualToString:@"phone"]) {
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
		} else if ([tag isEqualToString:@"office"]) {//|| [tag isEqualToString:@"room"]) {
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
		} else {
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			return cell;
		}
		
		return cell;
	}	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	
	NSInteger row = indexPath.row;
	NSInteger section = indexPath.section;
	if (section == [self.sectionArray count]) {
        return tableView.rowHeight;
		//return 44.0;
	}
	
	NSArray *personInfo = [[self.sectionArray objectAtIndex:section] objectAtIndex:row];
	NSString *tag = [personInfo objectAtIndex:0];
	NSString *data = [personInfo objectAtIndex:1];
	// the following may be off by a pixel or 2 for different OS versions
	// in the future we should prepare for the general case where widths can be way different (including flipping orientation)
	CGFloat labelWidth = ([tag isEqualToString:@"phone"] || [tag isEqualToString:@"email"] || [tag isEqualToString:@"office"]) ? 182.0 : 207.0;
	
	CGSize labelSize = [data sizeWithFont:[UIFont boldSystemFontOfSize:15.0]
						constrainedToSize:CGSizeMake(labelWidth, 2009.0f)
							lineBreakMode:UILineBreakModeWordWrap];
	
	return labelSize.height + 26.0;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == [self.sectionArray count]) { // user selected create/add to contacts
		
		if (indexPath.row == 0) { // create addressbook entry
			ABRecordRef person = ABPersonCreate();
			CFErrorRef error = NULL;
			NSString *value;
		
			// set single value properties
			if ((value = [self.personDetails valueForKey:@"givenname"]))
				ABRecordSetValue(person, kABPersonFirstNameProperty, value, &error);
			if ((value = [self.personDetails valueForKey:@"surname"]))
				ABRecordSetValue(person, kABPersonLastNameProperty, value, &error);
			if ((value = [self.personDetails valueForKey:@"title"]))
				ABRecordSetValue(person, kABPersonJobTitleProperty, value, &error);
			if ((value = [self.personDetails valueForKey:@"dept"]))
				ABRecordSetValue(person, kABPersonDepartmentProperty, value, &error);
		
			// set multivalue properties: email and phone numbers
			ABMutableMultiValueRef multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
			if ((value = [self.personDetails valueForKey:@"email"])) {
				for (NSString *email in [value componentsSeparatedByString:@","])
					ABMultiValueAddValueAndLabel(multiEmail, email, kABWorkLabel, NULL);
				ABRecordSetValue(person, kABPersonEmailProperty, multiEmail, &error);
			}
			CFRelease(multiEmail);
		
			BOOL haveValues = NO;
			ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
			if ((value = [self.personDetails valueForKey:@"phone"])) {
				for (NSString *phone in [value componentsSeparatedByString:@","])
					ABMultiValueAddValueAndLabel(multiPhone, phone, kABWorkLabel, NULL);
				ABRecordSetValue(person, kABPersonPhoneProperty, multiPhone, &error);
				haveValues = YES;
			}
			if ((value = [self.personDetails valueForKey:@"fax"])) {
				ABMultiValueAddValueAndLabel(multiPhone, value, kABPersonPhoneWorkFAXLabel, NULL);
				haveValues = YES;
			}
			if (haveValues) {
				ABRecordSetValue(person, kABPersonPhoneProperty, multiPhone, &error);
			}
			CFRelease(multiPhone);
			
			ABNewPersonViewController *creator = [[ABNewPersonViewController alloc] init];
			creator.displayedPerson = person;
			[creator setNewPersonViewDelegate:self];
			
			// present newPersonController in a separate navigationController
			// since it doesn't have its own nav bar
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:creator];
			
			MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
			[appDelegate presentAppModalViewController:navController animated:YES];

            CFRelease(person);
			[creator release];
			[navController release];
			
		} else {
			ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
			[picker setPeoplePickerDelegate:self];
			
			MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
			[appDelegate presentAppModalViewController:picker animated:YES];
			
			[picker release];
		}
		
	} else {
		
		NSArray *personInfo = [[self.sectionArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
		NSString *tag = [personInfo objectAtIndex:0];
		
		if ([tag isEqualToString:@"email"]) {
			[self emailIconTapped:[personInfo objectAtIndex:1]];
        } else if ([tag isEqualToString:@"phone"]) {
			[self phoneIconTapped:[personInfo objectAtIndex:1]];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        } else if ([tag isEqualToString:@"office"]) {
			[self mapIconTapped:[personInfo objectAtIndex:1]];
        }

	}
}

#pragma mark -
#pragma mark Address book new person methods

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonViewController didCompleteWithNewPerson:(ABRecordRef)person
{	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
}

#pragma mark Address book person controller methods

- (BOOL)        personViewController:(ABPersonViewController *)personViewController 
 shouldPerformDefaultActionForPerson:(ABRecordRef)person 
							property:(ABPropertyID)property 
						  identifier:(ABMultiValueIdentifier)identifierForValue
{
	return NO;
}

#pragma mark Address Book People Picker nav controller methods


/* when they pick a person we are recreating the entire record using
 * the union of what was previously there and what we received from
 * the server
 */
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker 
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	CFErrorRef error;
	
	ABAddressBookRef ab = ABAddressBookCreate();
	
	//ABPersonViewController *personController = [[ABPersonViewController alloc] init];
	//personController.personViewDelegate = self;
	//personController.allowsEditing = YES;
	//personController.displayedPerson = person;

	NSString *ldapValue = nil;
	ABRecordRef newPerson = ABPersonCreate();
	CFTypeRef recordValue = NULL;
	
	// get values for single-value properties
    recordValue = ABRecordCopyValue(person, kABPersonFirstNameProperty);
	if (recordValue != nil) {
		ABRecordSetValue(newPerson, kABPersonFirstNameProperty, recordValue, &error);
        CFRelease(recordValue);
    }
	else if ((ldapValue = [self.personDetails valueForKey:@"givenname"]))
		ABRecordSetValue(newPerson, kABPersonFirstNameProperty, ldapValue, &error);
	
    recordValue = ABRecordCopyValue(person, kABPersonLastNameProperty);
	if (recordValue != nil) {
        ABRecordSetValue(newPerson, kABPersonLastNameProperty, recordValue, &error);
        CFRelease(recordValue);
    }
	else if ((ldapValue = [self.personDetails valueForKey:@"surname"]))
		ABRecordSetValue(newPerson, kABPersonLastNameProperty, ldapValue, &error);
	
    recordValue = ABRecordCopyValue(person, kABPersonJobTitleProperty);
	if (recordValue != nil) {
        ABRecordSetValue(newPerson, kABPersonJobTitleProperty, recordValue, &error);
        CFRelease(recordValue);
    }
	else if ((ldapValue = [self.personDetails valueForKey:@"title"]))
		ABRecordSetValue(newPerson, kABPersonJobTitleProperty, ldapValue, &error);
	
    recordValue = ABRecordCopyValue(person, kABPersonDepartmentProperty);
	if (recordValue != nil) {
        ABRecordSetValue(newPerson, kABPersonDepartmentProperty, recordValue, &error);
        CFRelease(recordValue);
    }
	else if ((ldapValue = [self.personDetails valueForKey:@"dept"]))
		ABRecordSetValue(newPerson, kABPersonDepartmentProperty, ldapValue, &error);
		
	// multi value phone property
	ABMultiValueRef multi = ABRecordCopyValue(person, kABPersonPhoneProperty);
	ABMutableMultiValueRef phone = ABMultiValueCreateMutableCopy(multi);
	NSArray *existingPhones = (NSArray *)ABMultiValueCopyArrayOfAllValues(phone);
	if ((ldapValue = [self.personDetails valueForKey:@"phone"])) {
		for (NSString *value in [ldapValue componentsSeparatedByString:@","]) {
			if (![existingPhones containsObject:value]) {
				ABMultiValueAddValueAndLabel(phone, value, kABWorkLabel, NULL);
			}
		}
	}
	if ((ldapValue = [self.personDetails valueForKey:@"fax"]) && ![existingPhones containsObject:ldapValue]) {
		ABMultiValueAddValueAndLabel(phone, ldapValue, kABPersonPhoneWorkFAXLabel, NULL);
	}
	ABRecordSetValue(newPerson, kABPersonPhoneProperty, phone, &error);
	CFRelease(phone);
    CFRelease(multi);
	[existingPhones release];
	
	// multi value email property
	multi = ABRecordCopyValue(person, kABPersonEmailProperty);
	ABMutableMultiValueRef email = ABMultiValueCreateMutableCopy(multi);
	NSArray *existingEmails = (NSArray *)ABMultiValueCopyArrayOfAllValues(email);
	if ((ldapValue = [self.personDetails valueForKey:@"email"])) {
		for (NSString *value in [ldapValue componentsSeparatedByString:@","]) {
			if (![existingEmails containsObject:value]) {
				ABMultiValueAddValueAndLabel(email, value, kABWorkLabel, NULL);
			}
		}
	}
	ABRecordSetValue(newPerson, kABPersonEmailProperty, email, &error);
	CFRelease(email);
	[existingEmails release];

	CFRelease(multi);
	
	// save all the stuff we unilaterally overwrote with the user's barely informed consent
	ABAddressBookRemoveRecord(ab, person, &error);
    ABAddressBookAddRecord(ab, newPerson, &error);
    ABAddressBookHasUnsavedChanges(ab);
    ABAddressBookSave(ab, &error);
	CFRelease(newPerson);
    CFRelease(ab);
	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
	//[self.navigationController pushViewController:personController animated:YES];
	//[appDelegate presentAppModalViewController:personController animated:YES];
	
	return NO; // don't navigate to built-in view
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker 
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person 
								property:(ABPropertyID)property 
							  identifier:(ABMultiValueIdentifier)identifier
{
	return NO;
}
	
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
}

/*
#pragma mark -
#pragma mark Alert view delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != [alertView cancelButtonIndex]) {
		// we always set up the title to be "Dial xxxxxxxxxx?" or "Email xxx@xxx.xxx?"
		NSArray *titleParts = [alertView.title componentsSeparatedByString:@" "];
		NSString *titleAction = [titleParts objectAtIndex:1];
		titleAction = [titleAction substringToIndex:[titleAction length] - 1];
		NSString *urlString;
		
		if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Dial"])
			urlString = [@"tel://" stringByAppendingString:titleAction];
		else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Email"])
			urlString = [@"mailto://" stringByAppendingString:titleAction];
	
		NSURL *externURL = [NSURL URLWithString:urlString];
		[[UIApplication sharedApplication] openURL:externURL];
	}
}
*/

#pragma mark -
#pragma mark App-switching actions

- (void)mapIconTapped:(NSString *)room
{
	[[UIApplication sharedApplication] openURL:[NSURL internalURLWithModuleTag:CampusMapTag path:@"search" query:room]];	
}

- (void)phoneIconTapped:(NSString *)phone
{
	NSURL *externURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phone]];
	if ([[UIApplication sharedApplication] canOpenURL:externURL])
		[[UIApplication sharedApplication] openURL:externURL];
}

- (void)emailIconTapped:(NSString *)email
{
    [MITMailComposeController presentMailControllerWithRecipient:email subject:nil body:nil];
}


@end

