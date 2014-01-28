#import "PeopleDetailsViewController.h"
#import "PeopleDetailsTableViewCell.h"
#import "ConnectionDetector.h"
#import "PeopleRecentsData.h"
#import "MIT_MobileAppDelegate.h"
#import "MITUIConstants.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "MITMailComposeController.h"
#import "MobileRequestOperation.h"

#import "PeopleDetailsHeaderView.h"

@interface PeopleDetailsViewController ()
@property (nonatomic, strong) NSArray *attributeKeys;
@property (nonatomic, strong) NSArray *attributes;
@property (nonatomic, weak) IBOutlet UILabel * personName;
@property (nonatomic, weak) IBOutlet UILabel * personTitle;
@property (nonatomic, weak) IBOutlet UILabel * personOrganization;
@end

static NSString * AttributeCellReuseIdentifier = @"AttributeCell";

@implementation PeopleDetailsViewController
- (void)viewDidLoad
{
	self.title = @"Info";
	[self.tableView applyStandardColors];
    self.view.backgroundColor = [UIColor mit_backgroundColor];
    [self registerNibsForTableViewCells];

    self.attributeKeys = @[@"email", @"phone", @"fax", @"homephone", @"office", @"address", @"website"];

    [self mapPersonAttributes];
    [self updateTableViewHeaderView];
	
	// if lastUpdate is sufficiently long ago, issue a background search
	// TODO: change this time interval to something more reasonable
	if ([[self.personDetails valueForKey:@"lastUpdate"] timeIntervalSinceNow] < -300) { // 5 mins for testing
        MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:@"people"
                                                                                  command:nil
                                                                               parameters:@{@"q" : self.personDetails.displayName}];
        request.completeBlock = ^(MobileRequestOperation *operation, NSArray *contactResults, NSString *contentType, NSError *error) {
            if (!error) {
                [contactResults enumerateObjectsUsingBlock:^(NSDictionary *entry, NSUInteger idx, BOOL *stop) {
                    if ([entry[@"id"] isEqualToString:[self.personDetails valueForKey:@"uid"]]) {
                        self.personDetails = [PeopleRecentsData updatePerson:self.personDetails withSearchResult:entry];
                        [self updateTableViewHeaderView];
                        [self.tableView reloadData];
                        (*stop) = YES;
                    }
                }];
            }
        };
        
        [[MobileRequestOperation defaultQueue] addOperation:request];
	}
}

- (void) mapPersonAttributes
{
    NSMutableArray *tempAttributes = [NSMutableArray array];
    for (NSString *key in self.attributeKeys) {
        id attribute = [self.personDetails valueForKey:key];
        if ([attribute isKindOfClass:[NSString class]]) {
            [tempAttributes addObject:attribute];
        } else if ([attribute isKindOfClass:[NSArray class]]) {
            [tempAttributes addObjectsFromArray:attribute];
        }
    }
    self.attributes = [tempAttributes copy];
}

- (void) updateTableViewHeaderView
{
    self.personName.text = self.personDetails.displayName;
    self.personTitle.text = self.personDetails.title;
    self.personOrganization.text = self.personDetails.dept;
}

- (void) registerNibsForTableViewCells
{
    [self.tableView registerNib:[UINib nibWithNibName:@"PeopleDetailsTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:AttributeCellReuseIdentifier];
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

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// Return the number of rows in the section.
    switch (section) {
        case 0:
            return [self.attributes count];

        case 1:
            return 2;

        case 2:
            return 1;

        default:
            return 0;
    }
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;

	NSString *cellID = [NSString stringWithFormat:@"%d",section];
	
	if (section == 1) {
		// cells for Create New / Add Existing rows at the end
		// we are mimicking the style of UIButtonTypeRoundedRect until we find something more built-in
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
		
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
            cell.textLabel.textColor = STANDARD_CONTENT_FONT_COLOR;
        }

		if (row == 0) {
			cell.textLabel.text = @"Create New Contact";
        } else {
			cell.textLabel.text = @"Add to Existing Contact";
		}

		return cell;
		
	} else { // cells for displaying person details
		PeopleDetailsTableViewCell *cell = (PeopleDetailsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:AttributeCellReuseIdentifier];

		NSString *personInfo = self.attributes[row];
//		NSString *tag = [personInfo firstObject];
//		id data = personInfo[1];
//        if ([data isKindOfClass:[NSArray class]]) {
//            data = [data componentsJoinedByString:@", "];
//        }

//		cell.typeLabel.text = tag;
//		cell.valueLabel.text = data;

        cell.valueLabel.text = personInfo;

//		if ([tag isEqualToString:@"email"]) {
//            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
//		} else if ([tag isEqualToString:@"phone"]) {
//            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
//		} else if ([tag isEqualToString:@"office"]) {
//            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
//		} else {
//			cell.selectionStyle = UITableViewCellSelectionStyleNone;
//		}

		return cell;
	}	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	switch (indexPath.section) {
        case 0:
#pragma message "TODO: Need to make this dynamic"
            return 62.;

        case 1:
            return 44.;

        case 2:
        default:
            return 62.;
    }

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1) { // user selected create/add to contacts
		if (indexPath.row == 0) { // create addressbook entry
			ABRecordRef person = ABPersonCreate();
			CFErrorRef error = NULL;
			NSString *value = nil;;
		
			// set single value properties
			if ((value = [self.personDetails valueForKey:@"givenname"]))
				ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFTypeRef)value, &error);
			if ((value = [self.personDetails valueForKey:@"surname"]))
				ABRecordSetValue(person, kABPersonLastNameProperty, (__bridge CFTypeRef)value, &error);
			if ((value = [self.personDetails valueForKey:@"title"]))
				ABRecordSetValue(person, kABPersonJobTitleProperty, (__bridge CFTypeRef)value, &error);
			if ((value = [self.personDetails valueForKey:@"dept"]))
				ABRecordSetValue(person, kABPersonDepartmentProperty, (__bridge CFTypeRef)value, &error);
		
			// set multivalue properties: email and phone numbers
			ABMutableMultiValueRef multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
			if ((value = [self.personDetails valueForKey:@"email"])) {
				for (NSString *email in [value componentsSeparatedByString:@","])
					ABMultiValueAddValueAndLabel(multiEmail, (__bridge CFTypeRef)email, kABWorkLabel, NULL);
				ABRecordSetValue(person, kABPersonEmailProperty, multiEmail, &error);
			}

			CFRelease(multiEmail);
		
			BOOL haveValues = NO;
			ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
			if ((value = [self.personDetails valueForKey:@"phone"])) {
				for (NSString *phone in [value componentsSeparatedByString:@","])
					ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)phone, kABWorkLabel, NULL);
				ABRecordSetValue(person, kABPersonPhoneProperty, multiPhone, &error);
				haveValues = YES;
			}

			if ((value = [self.personDetails valueForKey:@"fax"])) {
				ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)value, kABPersonPhoneWorkFAXLabel, NULL);
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
		} else {
			ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
			[picker setPeoplePickerDelegate:self];
			
			MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
			[appDelegate presentAppModalViewController:picker animated:YES];
		}
	} else {
		NSArray *personInfo = self.attributes[indexPath.row];
		NSString *tag = personInfo[0];
		
		if ([tag isEqualToString:@"email"]) {
			[self emailIconTapped:personInfo[1]];
        } else if ([tag isEqualToString:@"phone"]) {
			[self phoneIconTapped:personInfo[1]];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        } else if ([tag isEqualToString:@"office"]) {
			[self mapIconTapped:personInfo[1]];
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

- (BOOL) personViewController:(ABPersonViewController *)personViewController
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
    } else if ((ldapValue = [self.personDetails valueForKey:@"givenname"])) {
		ABRecordSetValue(newPerson, kABPersonFirstNameProperty, (__bridge CFTypeRef)ldapValue, &error);
    }

    recordValue = ABRecordCopyValue(person, kABPersonLastNameProperty);
	if (recordValue != nil) {
        ABRecordSetValue(newPerson, kABPersonLastNameProperty, recordValue, &error);
        CFRelease(recordValue);
    } else if ((ldapValue = [self.personDetails valueForKey:@"surname"])) {
		ABRecordSetValue(newPerson, kABPersonLastNameProperty, (__bridge CFTypeRef)ldapValue, &error);
    }

    recordValue = ABRecordCopyValue(person, kABPersonJobTitleProperty);
	if (recordValue != nil) {
        ABRecordSetValue(newPerson, kABPersonJobTitleProperty, recordValue, &error);
        CFRelease(recordValue);
    } else if ((ldapValue = [self.personDetails valueForKey:@"title"])) {
		ABRecordSetValue(newPerson, kABPersonJobTitleProperty, (__bridge CFTypeRef)ldapValue, &error);
    }

    recordValue = ABRecordCopyValue(person, kABPersonDepartmentProperty);
	if (recordValue != nil) {
        ABRecordSetValue(newPerson, kABPersonDepartmentProperty, recordValue, &error);
        CFRelease(recordValue);
    } else if ((ldapValue = [self.personDetails valueForKey:@"dept"])) {
		ABRecordSetValue(newPerson, kABPersonDepartmentProperty, (__bridge CFTypeRef)ldapValue, &error);
    }

	// multi value phone property
	ABMultiValueRef multi = ABRecordCopyValue(person, kABPersonPhoneProperty);
	ABMutableMultiValueRef phone = ABMultiValueCreateMutableCopy(multi);
	NSArray *existingPhones = CFBridgingRelease(ABMultiValueCopyArrayOfAllValues(phone));
	if ((ldapValue = [self.personDetails valueForKey:@"phone"])) {
		for (NSString *value in [ldapValue componentsSeparatedByString:@","]) {
			if (![existingPhones containsObject:value]) {
				ABMultiValueAddValueAndLabel(phone, (__bridge CFTypeRef)value, kABWorkLabel, NULL);
			}
		}
	}

	if ((ldapValue = [self.personDetails valueForKey:@"fax"]) && ![existingPhones containsObject:ldapValue]) {
		ABMultiValueAddValueAndLabel(phone, (__bridge CFTypeRef)ldapValue, kABPersonPhoneWorkFAXLabel, NULL);
	}

    ABRecordSetValue(newPerson, kABPersonPhoneProperty, phone, &error);
	CFRelease(phone);
    CFRelease(multi);
	
	// multi value email property
	multi = ABRecordCopyValue(person, kABPersonEmailProperty);
	ABMutableMultiValueRef email = ABMultiValueCreateMutableCopy(multi);
	NSArray *existingEmails = CFBridgingRelease(ABMultiValueCopyArrayOfAllValues(email));
	if ((ldapValue = [self.personDetails valueForKey:@"email"])) {
		for (NSString *value in [ldapValue componentsSeparatedByString:@","]) {
			if (![existingEmails containsObject:value]) {
				ABMultiValueAddValueAndLabel(email, (__bridge CFTypeRef)value, kABWorkLabel, NULL);
			}
		}
	}
	ABRecordSetValue(newPerson, kABPersonEmailProperty, email, &error);
	CFRelease(email);

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

#pragma mark - App-switching actions

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

