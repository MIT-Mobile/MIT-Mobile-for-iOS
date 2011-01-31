#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "PersonDetails.h"
#import "MITMobileWebAPI.h"

@interface PeopleDetailsViewController : UITableViewController 
	<ABPeoplePickerNavigationControllerDelegate, 
	 ABNewPersonViewControllerDelegate, 
	 ABPersonViewControllerDelegate, 
	 //UIAlertViewDelegate, 
     JSONLoadedDelegate> 
{

	PersonDetails *personDetails;
	NSMutableArray *sectionArray;
	NSString *fullname;
}

@property (nonatomic, retain) PersonDetails *personDetails;
@property (nonatomic, retain) NSMutableArray *sectionArray;
@property (nonatomic, retain) NSString *fullname;

- (void)mapIconTapped:(NSString *)room;
- (void)phoneIconTapped:(NSString *)phone;
- (void)emailIconTapped:(NSString *)email;

@end

