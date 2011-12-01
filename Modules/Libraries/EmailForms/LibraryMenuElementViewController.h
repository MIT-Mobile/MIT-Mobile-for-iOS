#import <UIKit/UIKit.h>
#import "LibraryEmailFormViewController.h"


@interface LibraryMenuElementViewController : UITableViewController {
    NSInteger currentSelectedValue;
}

@property (nonatomic, retain)  MenuLibraryFormElement *menuElement;

#pragma mark UI actions
- (IBAction)cancelTapped:(id)sender;
- (IBAction)doneTapped:(id)sender;

@end
