#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "QRReaderHistoryData.h"

extern NSString * const kBatchScanningSettingKey;

@protocol MITScannerMgrDelegate <NSObject>

- (void)barCodeFound;
- (void)barCodeProcessed:(QRReaderResult *)result isBatchScanning:(BOOL)isBatchScanning;

@end

@interface MITScannerMgr : NSObject

@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, weak) id <MITScannerMgrDelegate> delegate;

- (instancetype)initWithScannerData:(QRReaderHistoryData *)scannerData;

- (void)setupCaptureSession;
- (void)setVideoOrientation;

- (void)startSessionCapture;
- (void)stopSessionCapture;

- (BOOL)isScanningSupported;

@end
