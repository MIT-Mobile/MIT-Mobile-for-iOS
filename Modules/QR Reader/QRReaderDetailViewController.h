#import <UIKit/UIKit.h>
#import "ShareDetailViewController.h"


@class QRReaderResult;
@interface QRReaderDetailViewController : ShareDetailViewController

@property (nonatomic,readonly,retain) QRReaderResult *scanResult;
@property (nonatomic,readonly,assign) IBOutlet UIImageView *qrImageView;
@property (nonatomic,readonly,assign) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic,readonly,assign) IBOutlet UITextView *textView;
@property (nonatomic,readonly,assign) IBOutlet UIButton *actionButton;
@property (nonatomic,readonly,assign) IBOutlet UIButton *shareButton;

+ (QRReaderDetailViewController*)detailViewControllerForResult:(QRReaderResult*)result;
- (IBAction)pressedShareButton:(id)sender;
- (IBAction)pressedActionButton:(id)sender;

@end
