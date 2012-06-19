#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>



@protocol QRReaderScanDelegate;
@class QRReaderOverlayView;

@interface QRReaderScanViewController : UIViewController <ZBarReaderViewDelegate,NSURLConnectionDelegate>{
    id<QRReaderScanDelegate> _scanDelegate;
    QRReaderOverlayView *_overlayView;
    ZBarReaderView *_readerView;
    UILabel *adviceLabel;
    BOOL _isCaptureActive;
    
    UIButton *_cancelButton;
    
}

@property (nonatomic,retain) id<QRReaderScanDelegate> scanDelegate;
@property (nonatomic,retain,readonly) IBOutlet QRReaderOverlayView *overlayView;
@property (nonatomic,retain,readonly) UILabel *adviceLabel;
@property (nonatomic,readonly) BOOL isCaptureActive;
@property (nonatomic, retain)  UIImage *qrcodeImage;

@end

@protocol QRReaderScanDelegate <NSObject>
@required
- (void)scanView:(QRReaderScanViewController*)scanView
   didScanResult:(NSString*)result
       fromImage:(UIImage*)image;
- (void)scanViewDidCancel:(QRReaderScanViewController*)scanView;
@end


@interface QRReaderScanViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@end
