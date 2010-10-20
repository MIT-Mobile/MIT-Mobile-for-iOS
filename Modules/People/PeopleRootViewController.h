#import <UIKit/UIKit.h>
#import "ConnectionWrapper.h"
#import "PeopleSearchViewController.h"

@interface PeopleRootViewController : PeopleSearchViewController <UINavigationControllerDelegate, UIActionSheetDelegate> {

	NSMutableArray *recents;
	NSString *searchHints;
}

@property (nonatomic, retain) NSMutableArray *recents;
@property (nonatomic, retain) NSString *searchHints;

- (void)showActionSheet;
- (void)phoneIconTapped;

@end
