#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "PersonDetails.h"

@interface PeopleDetailsViewController : UITableViewController 
	<ABPeoplePickerNavigationControllerDelegate, 
	 ABNewPersonViewControllerDelegate, 
	 ABPersonViewControllerDelegate>

@property (nonatomic, strong) PersonDetails *personDetails;
@property (nonatomic, copy) NSString *fullname;

- (void)mapIconTapped:(NSString *)room;
- (void)phoneIconTapped:(NSString *)phone;
- (void)emailIconTapped:(NSString *)email;

@end

