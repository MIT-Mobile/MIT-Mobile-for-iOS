#import <UIKit/UIKit.h>
#import "LibraryEmailFormViewController.h"

@class MenuLibraryFormElement;

@interface LibraryMenuElementViewController : UITableViewController
@property (nonatomic, strong)  MenuLibraryFormElement *menuElement;

#pragma mark UI actions
- (IBAction)cancelTapped:(id)sender;
- (IBAction)doneTapped:(id)sender;

@end
