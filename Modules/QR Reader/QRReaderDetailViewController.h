#import <UIKit/UIKit.h>
#import "ShareDetailViewController.h"

@class QRReaderResult;

@interface QRReaderDetailViewController : ShareDetailViewController
@property (readonly,strong) QRReaderResult *scanResult;

+ (QRReaderDetailViewController*)detailViewControllerForResult:(QRReaderResult*)result;
- (IBAction)pressedShareButton:(id)sender;
- (IBAction)pressedActionButton:(id)sender;

@end
