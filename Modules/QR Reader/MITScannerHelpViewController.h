#import <UIKit/UIKit.h>

@protocol MITScannerHelpViewControllerDelegate <NSObject>

- (void)helpViewControllerDidClose;

@end

@interface MITScannerHelpViewController : UIViewController
@property (weak) IBOutlet UILabel *helpTextView;
@property (weak) IBOutlet UIView *sampleImagesContainerView;

@property (weak, nonatomic) id <MITScannerHelpViewControllerDelegate> delegate;

@end
