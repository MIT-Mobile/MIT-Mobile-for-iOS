#import "MITScannerMgr.h"

NSString * const kBatchScanningSettingKey = @"kBatchScanningSettingKey";

@interface MITScannerMgr() <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;

@property (nonatomic, strong) NSMutableArray *allowedBarcodeTypes;

// boolean flag to check whether scan session is currently active or stopped
@property (nonatomic, assign) BOOL isCaptureActive;
// boolean flag that acts as a guard against processing more then one code at once
@property (nonatomic, assign) BOOL isBarcodeProcessingAlreadyInProgress;
@property (nonatomic, assign) BOOL isAdjustingFocus;

@property (strong) QRReaderHistoryData *scannerHistory;

@end

@implementation MITScannerMgr

- (instancetype)initWithScannerData:(QRReaderHistoryData *)scannerData
{
    self = [super init];
    if( self )
    {
        self.isCaptureActive = NO;
        self.scannerHistory = scannerData;
    }
    
    return self;
}

- (void)dealloc
{
    [self.captureDevice removeObserver:self forKeyPath:@"adjustingFocus"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if( [keyPath isEqualToString:@"adjustingFocus"] )
    {
        self.isAdjustingFocus = [ [change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1] ];
    }
}

- (void)setupCaptureSession
{
    if( self.captureSession != nil )
    {
        return;
    }
    
    NSError *error;
    
    // 1.
    self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if( self.captureDevice == nil )
    {
        NSLog(@"No video camera on this device!");
        return;
    }
    
    if( [self.captureDevice isFocusPointOfInterestSupported] )
    {
        [self.captureDevice lockForConfiguration:&error];
        CGPoint point = CGPointMake(0.5,0.5);
        [self.captureDevice setFocusPointOfInterest:point];
        [self.captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [self.captureDevice unlockForConfiguration];
        [self.captureDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    // 2.
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    
    // 3.
    self.deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.captureDevice error:&error];
    if( self.deviceInput == nil )
    {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    // 4.
    [self.captureSession addInput:self.deviceInput];
    
    
    // 5.
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self setVideoOrientation];
    
    // 6.
    self.metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [self.captureSession addOutput:self.metadataOutput];
    
    // 7.
    dispatch_queue_t metadataQueue = dispatch_queue_create("edu.mit.mobile.metadataQueue", 0);
    [self.metadataOutput setMetadataObjectsDelegate:self queue:metadataQueue];
    [self.metadataOutput setMetadataObjectTypes:self.allowedBarcodeTypes];
    
    // 8. another output to capture screenshots
    self.stillImageOutput = [AVCaptureStillImageOutput new];
    [self.captureSession addOutput:self.stillImageOutput];
}

- (void)setVideoOrientation
{
    AVCaptureVideoOrientation newOrientation = [self videoOrientationFromDeviceOrientation];
    [self.previewLayer.connection setVideoOrientation:newOrientation];
}

- (AVCaptureVideoOrientation)videoOrientationFromDeviceOrientation
{
    AVCaptureVideoOrientation videoOrientation;
    
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            // Not clear why but the landscape orientations are reversed
            // if I use AVCaptureVideoOrientationLandscapeRight here the pic ends up upside down
            videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            // Not clear why but the landscape orientations are reversed
            // if I use AVCaptureVideoOrientationLandscapeRight here the pic ends up upside down
            videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default:
            videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    
    return videoOrientation;
}

- (void)startSessionCapture
{
    if (self.isCaptureActive == NO)
    {
        self.isCaptureActive = YES;
        
        self.metadataOutput.metadataObjectTypes = self.metadataOutput.availableMetadataObjectTypes;
        
        BOOL doBatchScanning = [[NSUserDefaults standardUserDefaults] boolForKey:kBatchScanningSettingKey];
        float delay = doBatchScanning ? 1.0 : 0.2;
        
        dispatch_after(
                       dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                       dispatch_get_main_queue(),
                       ^{
                           [self.captureSession startRunning];
                       });
    }
}

- (void)stopSessionCapture
{
    if (self.isCaptureActive)
    {
        self.isCaptureActive = NO;
        [self.captureSession stopRunning];
    }
}

- (BOOL)isScanningSupported
{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

- (BOOL)isCaptureActive
{
    return (self->_isCaptureActive && self.isScanningSupported);
}

- (NSMutableArray *)allowedBarcodeTypes
{
    if( _allowedBarcodeTypes == nil )
    {
        _allowedBarcodeTypes = [NSMutableArray new];
        [_allowedBarcodeTypes addObject:AVMetadataObjectTypeQRCode];
        [_allowedBarcodeTypes addObject:AVMetadataObjectTypePDF417Code];
        [_allowedBarcodeTypes addObject:AVMetadataObjectTypeUPCECode];
        [_allowedBarcodeTypes addObject:AVMetadataObjectTypeAztecCode];
        [_allowedBarcodeTypes addObject:AVMetadataObjectTypeCode39Code];
        [_allowedBarcodeTypes addObject:AVMetadataObjectTypeCode39Mod43Code];
        [_allowedBarcodeTypes addObject:AVMetadataObjectTypeEAN13Code];
        [_allowedBarcodeTypes addObject:AVMetadataObjectTypeEAN8Code];
        [_allowedBarcodeTypes addObject:AVMetadataObjectTypeCode93Code];
        [_allowedBarcodeTypes addObject:AVMetadataObjectTypeCode128Code];
    }
    
    return _allowedBarcodeTypes;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if( self.isBarcodeProcessingAlreadyInProgress || self.isAdjustingFocus )
    {
        return;
    }

    self.isBarcodeProcessingAlreadyInProgress = YES;
    
    for( AVMetadataObject *metadata in metadataObjects )
    {
        if( [self.allowedBarcodeTypes containsObject:metadata.type] )
        {
            // found valid bar code to work with
            [self handleCodeFound:(AVMetadataMachineReadableCodeObject *)metadata completion:^{
                self.isBarcodeProcessingAlreadyInProgress = NO;
            }];
            
            return;
        }
    }
    
    // didn't find a valid code to process
    self.isBarcodeProcessingAlreadyInProgress = NO;
}

- (void)handleCodeFound:(AVMetadataMachineReadableCodeObject *)code
             completion:(void (^)(void))completionBlock
{
    [self.delegate barCodeFound];
    
    [self captureBarcodeImageWithCompletionHandler:^(UIImage *image) {
        [self stopSessionCapture];
        
        [self retrievedBarCodeImage:image forBarCode:code completion:completionBlock];
    }];
}

- (void)retrievedBarCodeImage:(UIImage *)image
                   forBarCode:(AVMetadataMachineReadableCodeObject *)code
                   completion:(void (^)(void))completionBlock
{
    [self.scannerHistory insertScanResult:code.stringValue
                                 withDate:[NSDate date]
                                withImage:image
                  shouldGenerateThumbnail:YES
                               completion:^(QRReaderResult *result, NSError *error) {
                                   [self postInsertOfResult:result];
                                   
                                   if( completionBlock ) completionBlock();
                               }];
}

- (void)postInsertOfResult:(QRReaderResult *)result
{
    if( result == nil )
    {
        return;
    }
    
    BOOL doBatchScanning = [[NSUserDefaults standardUserDefaults] boolForKey:kBatchScanningSettingKey];
    
    [self.delegate barCodeProcessed:result isBatchScanning:doBatchScanning];
}

- (void)captureBarcodeImageWithCompletionHandler:(void(^)(UIImage *))completionBlock
{
    __block UIImage *image;
    
    if( !self.isCaptureActive || self.isAdjustingFocus )
    {
        if( completionBlock ) completionBlock( nil );
        return;
    }
    
    AVCaptureConnection *videoConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                       completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         if( CMSampleBufferIsValid( imageSampleBuffer ) )
         {
             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
             image = [[UIImage alloc] initWithData:imageData];
         }
         
         if( image == nil )
         {
             NSLog(@"warn: missing screenshot");
         }
         
         if( completionBlock )
         {
             completionBlock( image );
         }
     }];
    
    [self stopSessionCapture];
}



@end
