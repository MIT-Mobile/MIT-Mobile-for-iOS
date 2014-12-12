#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "MITScannerViewController.h"
#import "MITScannerHistoryViewController.h"
#import "MITScannerOverlayView.h"
#import "QRReaderHistoryData.h"
#import "UIKit+MITAdditions.h"
#import "QRReaderResult.h"
#import "MITScannerHelpViewController.h"
#import "MITScannerDetailViewController.h"
#import "MITNavigationController.h"
#import "MITScannerAdvancedMenuViewController.h"
#import "MITBatchScanningAlertView.h"

FOUNDATION_STATIC_INLINE void runAsyncOnMainThread( dispatch_block_t blockToRun )
{
    dispatch_async(dispatch_get_main_queue(), blockToRun);
}

FOUNDATION_STATIC_INLINE void runAsyncOnBackgroundThread( dispatch_block_t blockToRun )
{
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), blockToRun );
}

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

// boolean flag to check whether scan session is currently active or stopped
@property (nonatomic,assign) BOOL isCaptureActive;
// boolean flag that acts as a guard against processing more then one code at once
@property (nonatomic, assign) BOOL isBarcodeProcessingAlreadyInProgress;
// on ipad the scan details show up as a form sheet.
@property (nonatomic,assign) BOOL isScanDetailsPresented;
// scanning is only supported on devices with camera
@property (readonly) BOOL isScanningSupported;

#pragma mark - History Properties
@property (strong) QRReaderHistoryData *scannerHistory;

#pragma mark - popovers
@property (nonatomic, strong) UIPopoverController *advancedMenuPopover;

#pragma mark - Private methods
- (void)ipad_showScanDetailsForScanResult:(QRReaderResult *)result;

- (IBAction)showHistory:(id)sender;
- (IBAction)showHelp:(id)sender;

- (void)startSessionCapture;
- (void)stopSessionCapture;
@end


@interface MITScannerViewController(ScanDetailViewDelegate) <MITScannerDetailViewControllerDelegate>

- (void)detailFormSheetViewDidDisappear;

@end

@interface MITScannerViewController(BatchScanAlertHandler) <MITBatchScanningAlertViewDelegate>

- (void)showAlertForScanResult:(QRReaderResult *)result;

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
        
        self.scannerHistory = [[QRReaderHistoryData alloc] init];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.isScanningSupported)
    {
        UIBarButtonItem *toolbarItem = [[UIBarButtonItem alloc] initWithTitle:@"History"
                                                                        style:UIBarButtonItemStyleBordered
                                                                       target:self
                                                                       action:@selector(showHistory:)];
        self.navigationItem.rightBarButtonItem = toolbarItem;
    }
    
    self.navigationController.toolbarHidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self makeNavigationBarTransparent];
    
    [self updateHistoryButtonTitle];
    
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self startSessionCapture];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopSessionCapture];
    
    [self.scannerHistory saveDataModelChanges];
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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self setVideoOrientation];
}

- (IBAction)showHistory:(id)sender
{
    [self.scannerHistory persistLastTimeHistoryWasOpened];
    
    if( [self isOnIpad] )
    {
        [self showHistoryOnIpad];
        
        return;
    }
    
    [self showHistoryOnIphone];
}

- (void)showHistoryOnIphone
{
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Scanner" style:UIBarButtonItemStyleBordered target:nil action:nil];
    [self.navigationController pushViewController:[MITScannerHistoryViewController new] animated:YES];
}

- (void)showHistoryOnIpad
{
    MITNavigationController *navController = [[MITNavigationController alloc] initWithRootViewController:[MITScannerHistoryViewController new]];
    UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    [popoverController setPopoverContentSize:CGSizeMake(320, 480) animated:NO];
    [popoverController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem
                              permittedArrowDirections:UIPopoverArrowDirectionUp
                                              animated:YES];
}

- (IBAction)showHelp:(id)sender
{
    MITScannerHelpViewController *vc = [[MITScannerHelpViewController alloc] init];
    UINavigationController *helpNavController = [[MITNavigationController alloc] initWithRootViewController:vc];
    helpNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController presentViewController:helpNavController animated:YES completion:NULL];
}

- (void)showAdvancedMenu:(id)sender
{
    if( [self isOnIpad] )
    {
        [self showAdvancedMenuOnIpad:sender];
        
        return;
    }
    
    [self showAdvancedMenuOnIphone:sender];
}

- (void)showAdvancedMenuOnIphone:(id)sender
{
    MITScannerAdvancedMenuViewController *vc = [MITScannerAdvancedMenuViewController new];
    UINavigationController *navController = [[MITNavigationController alloc] initWithRootViewController:vc];
    [self.navigationController presentViewController:navController animated:YES completion:NULL];
}

- (void)showAdvancedMenuOnIpad:(id)sender
{
    MITScannerAdvancedMenuViewController *advancedMenuVC = [MITScannerAdvancedMenuViewController new];
    self.advancedMenuPopover = [[UIPopoverController alloc] initWithContentViewController:advancedMenuVC];
    [self.advancedMenuPopover setPopoverContentSize:CGSizeMake(320, advancedMenuVC.menuViewHeight) animated:NO];    
    [self.advancedMenuPopover presentPopoverFromRect:[sender frame]
                                       inView:self.view
                     permittedArrowDirections:UIPopoverArrowDirectionDown
                                     animated:YES];
}

- (void)makeNavigationBarTransparent
{
    UIUserInterfaceIdiom userInterfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom;
    if (UIUserInterfaceIdiomPad == userInterfaceIdiom) {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = [UIImage new];
    }
}

- (NSString *)historyTitleWithNumberOfRecentScans:(NSInteger)numberOfRecentScans
{
    if( numberOfRecentScans > 0 )
    {
        return [NSString stringWithFormat:@"History (%li)", (long)numberOfRecentScans];
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
        self.isBarcodeProcessingAlreadyInProgress = NO;
        
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
    [self setVideoOrientation];
    
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

- (void)setVideoOrientation
{
    AVCaptureVideoOrientation newOrientation = [self videoOrientationFromDeviceOrientation];
    [self.previewLayer.connection setVideoOrientation:newOrientation];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if( self.isScanDetailsPresented || self.isBarcodeProcessingAlreadyInProgress )
    {
        return;
    }
    
    self.isBarcodeProcessingAlreadyInProgress = YES;
    
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
        
        // didn't find a code to process
        self.isBarcodeProcessingAlreadyInProgress = NO;
    }];
}

- (void)codeFound:(AVMetadataMachineReadableCodeObject *)code
{
    __weak MITScannerViewController *weakSelf = self;
    
    [self captureBarcodeImageWithCompletionHandler:^(UIImage *image) {
        
        if( image == nil )
        {
            // do not proceed and wait for a new scan which should be almost immediately.
            self.isBarcodeProcessingAlreadyInProgress = NO;
            return;
        }
        else
        {
            [weakSelf stopSessionCapture];
            [weakSelf proccessBarcode:code screenshot:image];
        }
    }];
}

- (void)captureBarcodeImageWithCompletionHandler:(void(^)(UIImage *))completionBlock
{
    __block UIImage *image;
    
    if( !self.isCaptureActive )
    {
        // TODO: how come capturing image happens after session is stopped capturing?
        // how to stop it? couldn't find 'close' method for connection.
        return;
    }
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo]
                                                       completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error)
    {
        if( CMSampleBufferIsValid( imageSampleBuffer ) )
        {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
            image = [[UIImage alloc] initWithData:imageData];
        }
        
        if( image == nil )
        {
            NSLog(@"warning: missing screenshot");
        }
        
        runAsyncOnBackgroundThread(^{
            if( completionBlock ) completionBlock( image );
        });
    }];
}

- (void)proccessBarcode:(AVMetadataMachineReadableCodeObject *)code screenshot:(UIImage *)screenshot
{
    runAsyncOnMainThread(^{
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        self.overlayView.highlighted = YES;
    });
    
    BOOL doBatchScanning = [[NSUserDefaults standardUserDefaults] boolForKey:kBatchScanningSettingKey];
    
    BOOL shouldGenerateThumbnail = [self isOnIpad] && doBatchScanning;
    
    QRReaderResult *result = [self.scannerHistory insertScanResult:code.stringValue
                                                          withDate:[NSDate date]
                                                         withImage:screenshot
                                           shouldGenerateThumbnail:shouldGenerateThumbnail];
    
    runAsyncOnMainThread(^{
        [self updateHistoryButtonTitle];
    });
    
    if ( doBatchScanning )
    {
        if( [self isOnIpad] )
        {
            [self showAlertForScanResult:result];
        }
        
        [self continueBatchScanning];
    }
    else
    {
        [self showScanDetailsForScanResult:result];
    }
}

- (void)continueBatchScanning
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        self.overlayView.highlighted = NO;
        
        [self startSessionCapture];
    });
}

- (void)showScanDetailsForScanResult:(QRReaderResult *)result
{
    if( [self isOnIpad] )
    {
        [self ipad_showScanDetailsForScanResult:result];
        
        return;
    }
    
    MITScannerDetailViewController *viewController = [MITScannerDetailViewController new];
    viewController.scanResult = result;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [self.navigationController pushViewController:viewController animated:YES];
        
        self.navigationController.navigationBar.userInteractionEnabled = YES;
        self.overlayView.highlighted = NO;
    });
}

- (void)ipad_showScanDetailsForScanResult:(QRReaderResult *)result
{
    self.isScanDetailsPresented = YES;
    
    MITScannerDetailViewController *viewController = [MITScannerDetailViewController new];
    viewController.delegate = self;
    viewController.scanResult = result;
    
    MITNavigationController *navController = [[MITNavigationController alloc] initWithRootViewController:viewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [self.navigationController presentViewController:navController animated:YES completion:^{
            self.navigationController.navigationBar.userInteractionEnabled = YES;
            self.overlayView.highlighted = NO;
            self.overlayView.hidden = YES;
            
            [self startSessionCapture];
        }];
    });
}

- (BOOL)isOnIpad
{
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

@end

#pragma mark - ScanDetailViewDelegate

@implementation MITScannerViewController(ScanDetailViewDelegate)

- (void)detailFormSheetViewDidDisappear
{
    self.overlayView.hidden = NO;
    self.isScanDetailsPresented = NO;
}

@end

@implementation MITScannerViewController(BatchScanAlertHandler)

- (void)showAlertForScanResult:(QRReaderResult *)result
{
    runAsyncOnMainThread(^{
        static MITBatchScanningAlertView *topAlert;
        static MITBatchScanningAlertView *bottomAlert;
        
        if( topAlert != nil )
        {
            if( bottomAlert != nil )
            {
                [bottomAlert removeFromSuperview];
                bottomAlert = nil;
            }
            
            CGRect topAlertFrame = topAlert.frame;
            topAlertFrame.origin.y += topAlertFrame.size.height + 5;
            topAlert.frame = topAlertFrame;
            bottomAlert = topAlert;
            topAlert = nil;
        }
        
        UINib *nib = [UINib nibWithNibName:NSStringFromClass([MITBatchScanningAlertView class]) bundle:nil];
        topAlert = [nib instantiateWithOwner:nil options:nil][0];
        topAlert.scanCodeLabel.text = result.text;
        topAlert.ScanThumbnailView.image = result.thumbnail;
        topAlert.scanId = result.objectID;
        topAlert.delegate = self;
        [self.view addSubview:topAlert];
        
        [topAlert fadeOutWithDuration:7.0 andWait:0.0];
    });
}

- (void)didTouchAlertView:(MITBatchScanningAlertView *)alertView
{
    if( self.isScanDetailsPresented )
    {
        return;
    }
    
    NSManagedObjectID *scanId = alertView.scanId;
    QRReaderResult *scanResult = [self.scannerHistory fetchScanResult:scanId];
    
    [self ipad_showScanDetailsForScanResult:scanResult];
}

@end
