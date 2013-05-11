#import <UIKit/UIKit.h>
#import "ShareDetailViewController.h"


@class QRReaderResult;
@interface QRReaderDetailViewController : ShareDetailViewController

@property (readonly,retain) QRReaderResult *scanResult;
@property (readonly,assign) UIScrollView *scrollView;
@property (readonly,assign) UIImageView *qrImageView;
@property (readonly,assign) UIImageView *backgroundImageView;
@property (readonly,assign) UILabel *textTitleLabel;
@property (readonly,assign) UILabel *textView;
@property (readonly,assign) UILabel *dateLabel;
@property (readonly,assign) UITableView *scanActionTable;

+ (QRReaderDetailViewController*)detailViewControllerForResult:(QRReaderResult*)result;
- (IBAction)pressedShareButton:(id)sender;
- (IBAction)pressedActionButton:(id)sender;

@end
