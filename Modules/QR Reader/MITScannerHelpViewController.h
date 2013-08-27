#import <UIKit/UIKit.h>

@interface MITScannerHelpViewController : UIViewController
@property (weak) IBOutlet UILabel *helpTextView;
@property (weak) IBOutlet UIImageView *backgroundImage;
@property (weak) IBOutlet UIBarButtonItem *doneButton;

- (IBAction)dismissHelp:(id)sender;

@end
