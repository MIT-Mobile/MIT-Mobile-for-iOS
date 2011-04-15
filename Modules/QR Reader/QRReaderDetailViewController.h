#import <UIKit/UIKit.h>
#import "ShareDetailViewController.h"


@class QRReaderResult;
@interface QRReaderDetailViewController : ShareDetailViewController <ShareItemDelegate> {
    QRReaderResult *_scanResult;
    UIImageView *_qrImage;
    UIImageView *_backgroundImageView;
    UITextView *_textView;
    UIButton *_actionButton;
    UIButton *_shareButton;
}

@property (nonatomic,readonly,retain) QRReaderResult *scanResult;
@property (nonatomic,readonly,retain) IBOutlet UIImageView *qrImage;
@property (nonatomic,readonly,retain) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic,readonly,retain) IBOutlet UITextView *textView;
@property (nonatomic,readonly,retain) IBOutlet UIButton *actionButton;
@property (nonatomic,readonly,retain) IBOutlet UIButton *shareButton;

+ (QRReaderDetailViewController*)detailViewControllerForResult:(QRReaderResult*)result;
- (IBAction)pressedShareButton:(id)sender;
- (IBAction)pressedActionButton:(id)sender;

@end
