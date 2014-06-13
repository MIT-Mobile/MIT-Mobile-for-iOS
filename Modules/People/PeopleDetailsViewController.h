#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "PersonDetails.h"

@interface PeopleDetailsViewController : UITableViewController 
	<ABPeoplePickerNavigationControllerDelegate, 
	 ABNewPersonViewControllerDelegate, 
	 ABPersonViewControllerDelegate>

@property (nonatomic, strong) PersonDetails *personDetails;

- (void)mapIconTapped:(NSString *)room;
- (void)phoneIconTapped:(NSString *)phone;
- (void)emailIconTapped:(NSString *)email;

- (void) reloadDataIfNeeded;
- (void) reload;

@end

