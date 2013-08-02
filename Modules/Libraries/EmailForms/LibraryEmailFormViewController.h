#import <UIKit/UIKit.h>
#import "LibraryFormElements.h"

@class LibraryFormElementGroup;
@class LibraryFormElement;
@class MITLoadingActivityView;

extern const NSInteger kLibraryEmailFormTextField;
extern const NSInteger kLibraryEmailFormTextView;


@interface LibraryEmailFormViewController : UITableViewController <UITextFieldDelegate, UIAlertViewDelegate> {
@private    
    NSArray *_formGroups;
    BOOL identityVerified;
}

- (NSString *)command;


@property (nonatomic, retain) MITLoadingActivityView *loadingView;
@property (nonatomic, retain) UISegmentedControl *prevNextSegmentedControl;
@property (nonatomic, retain) UIBarButtonItem *doneButton;
@property (nonatomic, readonly, retain) UIView *formInputAccessoryView;
@property (nonatomic, retain) UIResponder *currentTextView;

- (NSDictionary *)formValues;

- (LibraryFormElementGroup *)groupForName:(NSString *)name;
- (LibraryFormElement *)statusMenuFormElementWithRequired:(BOOL)required;

@end
