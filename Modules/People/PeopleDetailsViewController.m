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
    [super viewDidLoad];
	self.title = @"Info";
	[self.tableView applyStandardColors];
    self.view.backgroundColor = [UIColor mit_backgroundColor];

    self.attributeKeys = @[@"email", @"phone", @"fax", @"home", @"office", @"address", @"website"];

    [self mapPersonAttributes];
    [self updateTableViewHeaderView];
	
	// if lastUpdate is sufficiently long ago, issue a background search
	// TODO: change this time interval to something more reasonable
	if ([[self.personDetails valueForKey:@"lastUpdate"] timeIntervalSinceNow] < -300) { // 5 mins for testing
        MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:@"people"
                                                                                  command:nil
                                                                               parameters:@{@"q" : self.personDetails.name}];
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

static NSString * EmailAccessoryIcon    = @"email";
static NSString * PhoneAccessoryIcon    = @"phone";
static NSString * MapAccessoryIcon      = @"map";
static NSString * ExternalAccessoryIcon = @"external";

- (void) mapPersonAttributes
{
    /* key : display name : accessory icon
     * -----------------------------------
     * email     : email : email
     *
     * phone     : phone : phone
     * fax       : fax   : phone
     * homephone : home  : phone
     *
     * office            : office  : map
     * street/city/state : address : map
     *
     * website   : website : external
     */
    
    // The following section of code will initialize @property attributes with items structured:
    //   @[value for key, display name, accessory icon ]
    NSMutableArray *tempAttributes = [NSMutableArray array];
    for (NSString *key in self.attributeKeys) {
        id attribute = [self.personDetails valueForKey:key];
        
        NSString *attrAccessoryIcon = @"";
        if ([key isEqualToString:@"email"]) {
            attrAccessoryIcon = EmailAccessoryIcon;
        } else if ([@[@"phone", @"fax", @"home"] containsObject:key]) {
            attrAccessoryIcon = PhoneAccessoryIcon;
        } else if ([@[@"office", @"address"] containsObject:key]) {
            attrAccessoryIcon = MapAccessoryIcon;
        } else if ([key isEqualToString:@"website"]){
            attrAccessoryIcon = ExternalAccessoryIcon;
        }
        
        if ([attribute isKindOfClass:[NSString class]]) {
            NSArray * attrData = @[attribute, key, attrAccessoryIcon];
            [tempAttributes addObject:attrData];
        } else if ([attribute isKindOfClass:[NSArray class]]) {
            for (NSString *subAttribute in attribute) {
                NSArray *attrData = @[subAttribute, key, attrAccessoryIcon];
                [tempAttributes addObject:attrData];
            }
        }
    }
    self.attributes = [tempAttributes copy];
}

- (void) updateTableViewHeaderView
{
    self.personName.text = self.personDetails.name;
    self.personTitle.text = self.personDetails.title;
    self.personOrganization.text = self.personDetails.dept;
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

	UITableViewCell * cell;
	
	if (section == 1) {
		// cells for Create New / Add Existing rows at the end
		cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell" forIndexPath:indexPath];

		if (row == 0) {
			cell.textLabel.text = @"Create New Contact";
        } else {
			cell.textLabel.text = @"Add to Existing Contact";
		}
		
	} else if (section == 0) { // cells for displaying person details
		cell = [tableView dequeueReusableCellWithIdentifier:@"AttributeCell" forIndexPath:indexPath];

		NSArray *personInfo = self.attributes[row]; // see mapPersonAttributes method for creation of @property attributes
        NSString * attrValue    = personInfo[0];
        NSString * attrType     = personInfo[1];
        NSString * attrIcon     = personInfo[2];

        cell.detailTextLabel.text = attrValue;
        cell.textLabel.text = attrType;
        

		if ([attrIcon isEqualToString:EmailAccessoryIcon]) {
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
		} else if ([attrIcon isEqualToString:PhoneAccessoryIcon]) {
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
		} else if ([attrIcon isEqualToString:MapAccessoryIcon]) {
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
		} else if ([attrIcon isEqualToString:ExternalAccessoryIcon]) {
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
        } else {
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
        
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            // testing attributes attrType with the next attribute array
            //  like attribute types should not display separatorInsets
            if ([self.attributes count] > indexPath.row + 1 && [self.attributes[indexPath.row + 1][1] isEqualToString:self.attributes[indexPath.row][1]] ) {
                cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 1000.);
            } else {
                cell.separatorInset = UIEdgeInsetsMake(0, 15., 0, 0);
            }
        }

	} else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"BlankCell" forIndexPath:indexPath];
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 1000.);
        }
    }
    
    return cell;
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

