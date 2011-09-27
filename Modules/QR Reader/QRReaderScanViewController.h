#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "DecoderDelegate.h"

@protocol QRReaderScanDelegate;
@class QRReaderOverlayView;
@class FormatReader;

@interface QRReaderScanViewController : UIViewController <DecoderDelegate> {
    id<QRReaderScanDelegate> _scanDelegate;
    QRReaderOverlayView *_overlayView;
    UILabel *adviceLabel;
    BOOL _isCaptureActive;
    BOOL _decodedResult;
    
    FormatReader *_reader;
    
    UIButton *_cancelButton;
    
#if !defined(TARGET_IPHONE_SIMULATOR)
    AVCaptureSession *_captureSession;
    AVCaptureVideoPreviewLayer *_previewLayer;
#endif
}

@property (nonatomic,retain) id<QRReaderScanDelegate> scanDelegate;
@property (nonatomic,retain,readonly) IBOutlet QRReaderOverlayView *overlayView;
@property (nonatomic,retain,readonly) UILabel *adviceLabel;
@property (nonatomic,readonly) BOOL isCaptureActive;
@property (nonatomic,retain) FormatReader *reader;

+ (FormatReader*)defaultReader;
@end

@protocol QRReaderScanDelegate <NSObject>
@required
- (void)scanView:(QRReaderScanViewController*)scanView
   didScanResult:(NSString*)result
       fromImage:(UIImage*)image;
- (void)scanViewDidCancel:(QRReaderScanViewController*)scanView;
@end


#if !defined(TARGET_IPHONE_SIMULATOR)
@interface QRReaderScanViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@end
#endif
