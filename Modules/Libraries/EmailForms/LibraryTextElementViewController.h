#import <UIKit/UIKit.h>
#import "LibraryEmailFormViewController.h"


@interface LibraryTextElementViewController : UITableViewController 
<UITextFieldDelegate>
{
    
}

@property (nonatomic, retain) DedicatedViewTextLibraryFormElement *textElement;

#pragma mark UI actions
- (IBAction)cancelTapped:(id)sender;
- (IBAction)doneTapped:(id)sender;

@end
