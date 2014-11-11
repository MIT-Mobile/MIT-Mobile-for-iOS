#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "MITScannerViewController.h"
#import "MITScannerHistoryViewController.h"
#import "MITScannerOverlayView.h"
#import "QRReaderHistoryData.h"
#import "QRReaderDetailViewController.h"
#import "UIKit+MITAdditions.h"
#import "QRReaderResult.h"
#import "MITScannerHelpViewController.h"
#import "MITNavigationController.h"

@interface MITScannerViewController () <AVCaptureMetadataOutputObjectsDelegate>

#pragma mark - Scanner AVFoundation properties

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;

@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;

@property (nonatomic, strong) NSMutableArray *allowedBarcodeTypes;

#pragma mark - Scanner Properties
@property (strong) UIView *scanView;
@property (weak) UIImageView *cameraUnavailableView;
@property (weak) MITScannerOverlayView *overlayView;
@property (weak) UIButton *infoButton;
@property (weak) UIButton *advancedButton;

@property (nonatomic,assign) BOOL isCaptureActive;
@property (readonly) BOOL isScanningSupported;

#pragma mark - History Properties
@property (strong) QRReaderHistoryData *scannerHistory;

#pragma mark - Private methods
- (IBAction)showHistory:(id)sender;
- (IBAction)showHelp:(id)sender;

- (void)startSessionCapture;
- (void)stopSessionCapture;
@end
#pragma mark -

@implementation MITScannerViewController

- (instancetype)init
{
    return [self initWithNibName:nil bundle:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.isCaptureActive = NO;
    }
    return self;
}

- (BOOL)wantsFullScreenLayout
{
    return YES;
}

- (void)loadView
{
    UIView *controllerView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    controllerView.backgroundColor = [UIColor whiteColor];
    controllerView.autoresizesSubviews = YES;
    controllerView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleWidth);
    self.view = controllerView;

    if ([self.view respondsToSelector:@selector(setTintColor:)]) {
        self.view.tintColor = [UIColor whiteColor];
    }
    
    UIView *scannerView = [[UIView alloc] init];
    scannerView.autoresizesSubviews = YES;
    scannerView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                    UIViewAutoresizingFlexibleWidth);
    scannerView.backgroundColor = [UIColor blackColor];

    if (self.isScanningSupported) {
        [self setupCaptureSession];
    } else {
        UIImageView *unsupportedView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageScannerCameraUnsupported]];
        unsupportedView.contentMode = UIViewContentModeCenter;
        [scannerView addSubview:unsupportedView];
        self.cameraUnavailableView = unsupportedView;
    }

    CGRect frame = self.view.bounds;
    MITScannerOverlayView *overlay = [[MITScannerOverlayView alloc] initWithFrame:frame];
    overlay.backgroundColor = [UIColor clearColor];
    overlay.userInteractionEnabled = NO;
    overlay.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin |
                                UIViewAutoresizingFlexibleWidth);
    if (self.isScanningSupported) {
        overlay.helpText = @"To scan a QR code or barcode, frame it below.\nAvoid glare and shadows.";
    } else {
        overlay.helpText = @"A camera is required to scan QR codes and barcodes";
    }

    [scannerView addSubview:overlay];
    self.overlayView = overlay;

    UIButton *infoButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [infoButton setTitle:@"Info" forState:UIControlStateNormal];
    [infoButton sizeToFit];
    [infoButton addTarget:self action:@selector(showHelp:) forControlEvents:UIControlEventTouchUpInside];
    [scannerView addSubview:infoButton];
    self.infoButton = infoButton;

    UIButton *advancedButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [advancedButton setTitle:@"Advanced" forState:UIControlStateNormal];
    [advancedButton sizeToFit];
    [advancedButton addTarget:self action:@selector(showAdvancedMenu:) forControlEvents:UIControlEventTouchUpInside];
    [scannerView addSubview:advancedButton];
    self.advancedButton = advancedButton;
    
    [controllerView addSubview:scannerView];
    self.scanView = scannerView;
}

- (void)viewWillLayoutSubviews
{
    self.scanView.frame = self.view.bounds;
    {
        CGRect scannerContentBounds = self.scanView.bounds;
        
        if (self.isScanningSupported)
        {
            self.previewLayer.frame = scannerContentBounds;
            [self.scanView.layer insertSublayer:self.previewLayer atIndex:0];
        }
        else
        {
            CGRect cameraFrame = scannerContentBounds;
            cameraFrame.origin.y += 44.;
            self.cameraUnavailableView.frame = cameraFrame;
        }

        self.overlayView.frame = scannerContentBounds;

        CGRect frame = self.advancedButton.bounds;
        frame.origin.x = CGRectGetMaxX(scannerContentBounds) - (CGRectGetWidth(frame) + 20.); //20px -> standard spacing between a view and it's superview
        frame.origin.y = CGRectGetMaxY(scannerContentBounds) - (CGRectGetHeight(frame) + 20.);
        self.advancedButton.frame = frame;
        
        CGRect infoBtnFrame = self.infoButton.bounds;
        infoBtnFrame.origin.x = CGRectGetMinX(scannerContentBounds) + 20.;
        infoBtnFrame.origin.y = frame.origin.y;
        self.infoButton.frame = infoBtnFrame;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *menuBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:MITImageBarButtonMenu] style:UIBarButtonItemStylePlain target:self action:@selector(menuButtonPressed)];
    menuBarButton.tintColor = [UIColor whiteColor];
    [self.navigationItem setLeftBarButtonItem:menuBarButton];
    
    if (self.isScanningSupported)
    {
        UIBarButtonItem *toolbarItem = [[UIBarButtonItem alloc] initWithTitle:@"History"
                                                                        style:UIBarButtonItemStyleBordered
                                                                       target:self
                                                                       action:@selector(showHistory:)];
        toolbarItem.tintColor = [UIColor whiteColor];
        self.navigationItem.rightBarButtonItem = toolbarItem;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self makeNavigationBarTransparent];
    
    [self updateHistoryButtonTitle];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self startSessionCapture];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopSessionCapture];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)showHistory:(id)sender
{
    [self.scannerHistory persistLastTimeHistoryWasOpened];
    
    [self.navigationController pushViewController:[MITScannerHistoryViewController new] animated:YES];
}

- (IBAction)showHelp:(id)sender
{
    MITScannerHelpViewController *vc = [[MITScannerHelpViewController alloc] init];
    UINavigationController *helpNavController = [[MITNavigationController alloc] initWithRootViewController:vc];
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        helpNavController.navigationBar.barStyle = UIBarStyleDefault;
    } else {
        helpNavController.navigationBar.barStyle = UIBarStyleBlack;
    }
    helpNavController.navigationBar.translucent = NO;
    [self.navigationController presentViewController:helpNavController animated:YES completion:NULL];
}

- (void)makeNavigationBarTransparent
{
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
}

- (void)makeNavigationBarVisible
{
    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = nil;
    self.navigationController.navigationBar.translucent = NO;
}

- (void)menuButtonPressed
{
    [self.navigationController popViewControllerAnimated:YES];
    
    [self makeNavigationBarVisible];
}

- (NSString *)historyTitleWithNumberOfRecentScans:(NSInteger)numberOfRecentScans
{
    if( numberOfRecentScans > 0 )
    {
        return [NSString stringWithFormat:@"History (%i)", numberOfRecentScans];
    }
    
    return @"History";
}

- (void)updateHistoryButtonTitle
{
    NSArray *recentScans = [self.scannerHistory fetchRecentScans];
    
    self.navigationItem.rightBarButtonItem.title = [self historyTitleWithNumberOfRecentScans:[recentScans count]];
}

#pragma mark - Scanning Methods

- (BOOL)isCaptureActive
{
    return (self->_isCaptureActive && self.isScanningSupported);
}

- (void)startSessionCapture
{
    if (self.isCaptureActive == NO)
    {
        self.isCaptureActive = YES;
        
        [self.captureSession startRunning];
        self.metadataOutput.metadataObjectTypes = self.metadataOutput.availableMetadataObjectTypes;
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

- (void)setupCaptureSession
{
    if( self.captureSession != nil ) {
        return;
    }
    
    // 1.
    self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if( self.captureDevice == nil )
    {
        NSLog(@"No video camera on this device!");
        return;
    }
    
    // 2.
    self.captureSession = [[AVCaptureSession alloc] init];
    
    // 3.
    self.deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.captureDevice error:nil];
    
    // 4.
    if( [self.captureSession canAddInput:self.deviceInput] )
    {
        [self.captureSession addInput:self.deviceInput];
    }

    // 5.
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    // 6.
    self.metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    dispatch_queue_t metadataQueue = dispatch_queue_create("edu.mit.mobile.metadataQueue", 0);
    [self.metadataOutput setMetadataObjectsDelegate:self queue:metadataQueue];
    
    // 7.
    if( [self.captureSession canAddOutput:self.metadataOutput] )
    {
        [self.captureSession addOutput:self.metadataOutput];
    }
    
    // 8. another output to capture screenshots
    self.stillImageOutput = [AVCaptureStillImageOutput new];
    if( [self.captureSession canAddOutput:self.stillImageOutput] )
    {
        [self.captureSession addOutput:self.stillImageOutput];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    [metadataObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if( [obj isKindOfClass:[AVMetadataMachineReadableCodeObject class]] )
        {
            AVMetadataObject *metadataObject = [self.previewLayer transformedMetadataObjectForMetadataObject:obj];
            AVMetadataMachineReadableCodeObject *code =  (AVMetadataMachineReadableCodeObject*)metadataObject;
            
            for( NSString *allowedCodeType in self.allowedBarcodeTypes )
            {
                if( [code.type isEqualToString:allowedCodeType] )
                {
                    [self codeFound:code];
                    
                    return;
                }
            }
        }
    }];
}

- (void)codeFound:(AVMetadataMachineReadableCodeObject *)code
{
    __weak MITScannerViewController *weakSelf = self;
    
    [self captureBarcodeImageWithCompletionHandler:^(UIImage *image) {
        
        if( image == nil )
        {
            // do not proceed and wait for a new scan which should be almost immediately.
            return;
        }
        else
        {
            NSLog(@"code found and image captured");
            
            [weakSelf stopSessionCapture];
            [weakSelf proccessBarcode:code screenshot:image];
        }
    }];
}

- (void)captureBarcodeImageWithCompletionHandler:(void(^)(UIImage *))completionBlock
{
    __block UIImage *image;
    
    __weak MITScannerViewController *weakSelf = self;
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo]
                                                       completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         NSLog(@"capturing still image");
         
         if( !weakSelf.isCaptureActive )
         {
             // TODO: how come capturing image happens after session is stopped capturing?
             // how to stop it? couldn't find 'close' method for connection.
             return;
         }
         
         if( imageSampleBuffer != nil )
         {
             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
             image = [[UIImage alloc] initWithData:imageData];
         }
         
         if( image == nil )
         {
             NSLog(@"missing screenshot");
         }
         
         if( completionBlock ) completionBlock( image );
     }];
}

- (void)proccessBarcode:(AVMetadataMachineReadableCodeObject *)code screenshot:(UIImage *)screenshot
{
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    self.overlayView.highlighted = YES;
    
    QRReaderResult *result = [self.scannerHistory insertScanResult:code.stringValue
                                                          withDate:[NSDate date]
                                                         withImage:screenshot];
    
    [self updateHistoryButtonTitle];
    
    QRReaderDetailViewController *viewController = [QRReaderDetailViewController detailViewControllerForResult:result];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [self.navigationController pushViewController:viewController
                                             animated:YES];
        
        self.navigationController.navigationBar.userInteractionEnabled = YES;
        self.overlayView.highlighted = NO;
    });
}

@end
