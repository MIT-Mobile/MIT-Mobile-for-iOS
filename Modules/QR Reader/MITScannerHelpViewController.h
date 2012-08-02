//
//  MITScannerHelpViewController.h
//  MIT Mobile
//
//  Created by Blake Skinner on 8/2/12.
//
//

#import <UIKit/UIKit.h>

@interface MITScannerHelpViewController : UIViewController
@property (assign) IBOutlet UILabel *helpTextView;
@property (assign) IBOutlet UIImageView *backgroundImage;
@property (assign) IBOutlet UIBarButtonItem *doneButton;

- (IBAction)dismissHelp:(id)sender;

@end
