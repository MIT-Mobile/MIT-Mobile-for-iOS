#import <MessageUI/MessageUI.h>

#import "PeopleDetailsViewController.h"
#import "ConnectionDetector.h"
#import "PeopleFavoriteData.h"
#import "MIT_MobileAppDelegate.h"
#import "MITUIConstants.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "MITPeopleResource.h"
#import "MITNavigationController.h"
#import "MITMapModelController.h"

static NSString * EmailAccessoryIcon    = @"email";
static NSString * PhoneAccessoryIcon    = @"phone";
static NSString * MapAccessoryIcon      = @"map";
static NSString * ExternalAccessoryIcon = @"external";

static NSInteger AttributeValueIndex    = 0;
static NSInteger DisplayNameIndex       = 1;
static NSInteger AccessoryIconIndex     = 2;

@interface PeopleDetailsViewController () <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSArray *attributes;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerLeftIndentLayoutConstraint;
@property (nonatomic, weak) IBOutlet UILabel * personName;
@property (nonatomic, weak) IBOutlet UILabel * personTitle;
@property (nonatomic, weak) IBOutlet UILabel * personOrganization;

@end

static NSString * AttributeCellReuseIdentifier = @"AttributeCell";

@implementation PeopleDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self adjustTableViewInsets];
    
    [self updateTableViewHeaderView];
	   
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) reload
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self updateTableViewHeaderView];
        [self.tableView reloadData];
    }];
}

- (void) setPersonDetails:(PersonDetails *)personDetails
{
    _personDetails = personDetails;
    
    if( _personDetails )
    {
        [self mapPersonAttributes];
    }
    
    [self reload];
}


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
    
    // The following section of code will initialize @property 'attributes' with items structured:
    //   @[value for key, display name, accessory icon ]
    NSMutableArray *tempAttributes = [NSMutableArray array];
    NSArray *attributeKeys = @[@"email", @"phone", @"fax", @"home", @"office", @"address", @"website"];
    for (NSString *key in attributeKeys) {
        id attribute = [self.personDetails valueForKey:key];
        
        NSString *attrAccessoryIcon = [self accessoryIconForKey:key];
        
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

- (NSString *)accessoryIconForKey:(NSString *)key
{
    if ([key isEqualToString:@"email"]) {
        return EmailAccessoryIcon;
    } else if ([@[@"phone", @"fax", @"home"] containsObject:key]) {
        return PhoneAccessoryIcon;
    } else if ([@[@"office", @"address"] containsObject:key]) {
        return MapAccessoryIcon;
    } else if ([key isEqualToString:@"website"]){
       return ExternalAccessoryIcon;
    }
    return @"";
}

- (void) updateTableViewHeaderView
{
    if (self.personDetails) {
        self.personName.text = self.personDetails.name;
        self.personTitle.text = self.personDetails.title;
        self.personOrganization.text = self.personDetails.dept;
        
        [self.headerView setNeedsLayout];
        [self.headerView layoutIfNeeded];
        
        CGSize size = [self.headerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        
        CGRect frame = self.headerView.frame;
        frame.size.height = size.height;
        self.headerView.frame = frame;
        
        return;
    }

    self.personTitle.text = @"";
    self.personName.text = @"";
    self.personOrganization.text = @"";
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

#pragma mark - UI configs

- (void) adjustTableViewInsets
{
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone )
    {
        return;
    }
    
    UIEdgeInsets insets = UIEdgeInsetsMake([self topBarHeight], 0, 0, 0);
    
    self.tableView.contentInset = insets;
    self.tableView.scrollIndicatorInsets = insets;
}

- (CGFloat) topBarHeight
{
    CGSize statusBarSize = [UIApplication sharedApplication].statusBarFrame.size;
    return CGRectGetHeight(self.navigationController.navigationBar.frame) + MIN(statusBarSize.width, statusBarSize.height);
}

- (CGFloat) landscapeHeightDelta
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    
    return size.height - size.width;
}

#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if( !self.personDetails )
    {
        return 0;
    }
    
	return 2;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// Return the number of rows in the section.
    switch (section) {
        case 0:
            return [self.attributes count];

        case 1:
            
            return 3;

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
        } else if( row == 1 ) {
			cell.textLabel.text = @"Add to Existing Contact";
		} else if( row == 2 ) {
            
            if( self.personDetails.favorite )
            {
                cell.textLabel.text = @"Remove from Favorites";
            }
            else
            {
                cell.textLabel.text = @"Add to Favorites";
            }
            
            if( [cell respondsToSelector:@selector(setSeparatorInset:)] )
            {
                cell.separatorInset = UIEdgeInsetsMake(0.f, 0.f, 0.f, self.view.frame.size.height);
            }
        }
		
	} else { // (section == 0) cells for displaying person details
		cell = [tableView dequeueReusableCellWithIdentifier:@"AttributeCell" forIndexPath:indexPath];

		NSArray *personInfo = self.attributes[row]; // see mapPersonAttributes method for creation of @property attributes
        NSString * attrValue    = personInfo[AttributeValueIndex];
        NSString * attrType     = personInfo[DisplayNameIndex];
        NSString * attrIcon     = personInfo[AccessoryIconIndex];

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
            // testing attributes accessoryIcon with the next attribute array
            //  like accessory icons should not display separatorInsets
            if ([self.attributes count] > indexPath.row + 1 && [self.attributes[indexPath.row + 1][AccessoryIconIndex] isEqualToString:self.attributes[indexPath.row][AccessoryIconIndex]] ) {
                cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 1000.);
            } else {
                cell.separatorInset = UIEdgeInsetsMake(0, 15., 0, 0);
            }
        }

	}
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	switch (indexPath.section) {
        case 0:
        {
            NSArray *personInfo = self.attributes[indexPath.row];
            NSString * attrValue = personInfo[AttributeValueIndex];

            // Quick and dirty sizing for the 3.5 release. Needs to be replaced later
            NSDictionary *fontAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:16.]};
            NSAttributedString *sizingString = [[NSAttributedString alloc] initWithString:attrValue attributes:fontAttributes];

            // the 30.px size here is a rough estimate, assuming 15px insets
            // on either side of the contentView in the 'AttributeCell'
            CGSize maximumSize = CGSizeMake(CGRectGetWidth(tableView.bounds) - 30., CGFLOAT_MAX);
            CGFloat height = CGRectGetHeight([sizingString boundingRectWithSize:maximumSize
                                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                                           context:nil]);

            // Calculated from the storyboard on 2014.02.28 (bskinner)
            // Height of the 'AttributeCell', minus the 20px
            // display size of the value label
            return 42 + fabs(ceil(height));
        }

        case 1:
        default:
            return UITableViewAutomaticDimension;
    }

}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0)
    {
        [self tableView:tableView didSelectAttributeRowAtIndexPath:indexPath];
	}
    else
    {
        // user selected create/add to contacts/favorites
        [self tableView:tableView didSelectActionRowAtIndexPath:indexPath];
	}
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectAttributeRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *personInfo = self.attributes[indexPath.row];
    NSString *actionIcon = personInfo[AccessoryIconIndex];
    NSString * value = personInfo[AttributeValueIndex];
    
    if ([actionIcon isEqualToString:EmailAccessoryIcon]) {
        [self emailIconTapped:value];
    } else if ([actionIcon isEqualToString:PhoneAccessoryIcon]) {
        [self phoneIconTapped:value];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if ([actionIcon isEqualToString:MapAccessoryIcon]) {
        [self mapIconTapped:value];
    } else if ([actionIcon isEqualToString:ExternalAccessoryIcon]) {
        [self externalIconTapped:value];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didSelectActionRowAtIndexPath:(NSIndexPath *)indexPath
{
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
            for (NSString *email in self.personDetails.email)
                ABMultiValueAddValueAndLabel(multiEmail, (__bridge CFTypeRef)email, kABWorkLabel, NULL);
            ABRecordSetValue(person, kABPersonEmailProperty, multiEmail, &error);
        }
        
        CFRelease(multiEmail);
		
        BOOL haveValues = NO;
        ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        if ((value = [self.personDetails valueForKey:@"phone"])) {
            for (NSString *phone in self.personDetails.phone) {
                ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)phone, kABWorkLabel, NULL);
            }
            ABRecordSetValue(person, kABPersonPhoneProperty, multiPhone, &error);
            haveValues = YES;
        }
        
        if ((value = [self.personDetails valueForKey:@"fax"])) {
            for (NSString *fax in self.personDetails.fax) {
                ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)fax, kABPersonPhoneWorkFAXLabel, NULL);
            }
            ABRecordSetValue(person, kABPersonPhoneProperty, multiPhone, &error);
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
        UINavigationController *navController = [[MITNavigationController alloc] initWithRootViewController:creator];
        
        if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        [self presentViewController:navController animated:YES completion:nil];
        
        CFRelease(person);
    }
    else if( indexPath.row == 1 )
    {
        ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        [picker setPeoplePickerDelegate:self];
        
        if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            picker.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        [self presentViewController:picker animated:YES completion:nil];
    }
    else if( indexPath.row == 2 )
    {
        [PeopleFavoriteData setPerson:self.personDetails asFavorite:!self.personDetails.favorite];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark -
#pragma mark Address book new person methods
- (void)newPersonViewController:(ABNewPersonViewController *)newPersonViewController didCompleteWithNewPerson:(ABRecordRef)person
{	
    [newPersonViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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
	
	ABAddressBookRef ab = ABAddressBookCreateWithOptions(NULL, &error);

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
    NSArray *ldapValues = [self.personDetails valueForKey:@"phone"];
	if ( ldapValues )
    {
		for (NSString *value in ldapValues)
        {
			if (![existingPhones containsObject:value])
            {
				ABMultiValueAddValueAndLabel(phone, (__bridge CFTypeRef)value, kABWorkLabel, NULL);
			}
		}
	}

    ldapValues = [self.personDetails valueForKey:@"fax"];
    if( ldapValues )
    {
        for( NSString *value in ldapValues )
        {
            if( ![existingPhones containsObject:value] )
            {
                ABMultiValueAddValueAndLabel(phone, (__bridge CFTypeRef)value, kABPersonPhoneWorkFAXLabel, NULL);
            }
        }
    }

    ABRecordSetValue(newPerson, kABPersonPhoneProperty, phone, &error);
	CFRelease(phone);
    CFRelease(multi);
	
	// multi value email property
	multi = ABRecordCopyValue(person, kABPersonEmailProperty);
	ABMutableMultiValueRef email = ABMultiValueCreateMutableCopy(multi);
	NSArray *existingEmails = CFBridgingRelease(ABMultiValueCopyArrayOfAllValues(email));
    ldapValues = [self.personDetails valueForKey:@"email"];
	if ( ldapValues )
    {
		for (NSString *value in ldapValues)
        {
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

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - App-switching actions

- (void)mapIconTapped:(NSString *)room
{
    if (room) {
        [MITMapModelController openMapWithUnsanitizedSearchString:room];
    }
}

- (void)phoneIconTapped:(NSString *)phone
{
	NSURL *externURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phone]];
	if ([[UIApplication sharedApplication] canOpenURL:externURL]) {
		[[UIApplication sharedApplication] openURL:externURL];
    }
}

- (void)emailIconTapped:(NSString *)email
{
    if ([MFMailComposeViewController canSendMail]) {
        NSParameterAssert(email);
        
        MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] init];
        [composeViewController setToRecipients:@[email]];
        composeViewController.mailComposeDelegate = self;
        [self presentViewController:composeViewController animated:YES completion:nil];
    }
}

- (void)externalIconTapped:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

#pragma mark MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if ([self.presentedViewController isEqual:controller]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end

