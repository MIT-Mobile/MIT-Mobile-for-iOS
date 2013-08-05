#import <UIKit/UIKit.h>

@class DedicatedViewTextLibraryFormElement;

@interface LibraryTextElementViewController : UITableViewController <UITextFieldDelegate>
@property (strong) DedicatedViewTextLibraryFormElement *textElement;

#pragma mark UI actions
- (IBAction)cancelTapped:(id)sender;
- (IBAction)doneTapped:(id)sender;
@end
