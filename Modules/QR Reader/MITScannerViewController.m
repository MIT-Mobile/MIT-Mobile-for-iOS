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
#import "MITScannerMgr.h"

#define FIRST_ALERT_POSITION_TAG 20
#define SECOND_ALERT_POSITION_TAG 21

@interface MITScannerViewController ()

#pragma mark - Scanner UI components
@property (strong) UIView *scanView;
@property (weak) UIImageView *cameraUnavailableView;
@property (weak) MITScannerOverlayView *overlayView;
@property (weak) UIButton *infoButton;
@property (weak) UIButton *advancedButton;

@property (nonatomic, strong) MITScannerMgr *scannerMgr;

#pragma mark - History Properties
@property (strong) QRReaderHistoryData *scannerHistory;

#pragma mark - popovers
@property (nonatomic, strong) UIPopoverController *advancedMenuPopover;
@property (nonatomic, strong) UIPopoverController *historyPopoverController;

#pragma mark - Private methods
- (IBAction)showHistory:(id)sender;
- (IBAction)showHelp:(id)sender;
@end

#pragma mark - categories
@interface MITScannerViewController(ScanDetailViewDelegate) <MITScannerDetailViewControllerDelegate>
- (void)detailFormSheetViewDidDisappear;
@end

@interface MITScannerViewController(BatchScanAlertHandler) <MITBatchScanningAlertViewDelegate>
- (void)showAlertForScanResult:(QRReaderResult *)result;
- (void)removeVisibleScanningAlerts;
@end

@interface MITScannerViewController(DelegatesHandler) <UIPopoverControllerDelegate, MITScannerHelpViewControllerDelegate, MITScannerMgrDelegate>
- (void)helpViewControllerDidClose;
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
        self.scannerHistory = [QRReaderHistoryData new];
        self.scannerMgr = [[MITScannerMgr alloc] initWithScannerData:self.scannerHistory];;
        self.scannerMgr.delegate = self;
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
    scannerView.autoresizingMask = UIViewAutoresizingNone;
    scannerView.backgroundColor = [UIColor blackColor];

    if( [self.scannerMgr isScanningSupported] )
    {
        [self.scannerMgr setupCaptureSession];
    }
    else
    {
        UIImageView *unsupportedView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageScannerCameraUnsupported]];
        unsupportedView.contentMode = UIViewContentModeCenter;
        [scannerView addSubview:unsupportedView];
        self.cameraUnavailableView = unsupportedView;
    }

    CGRect frame = self.view.bounds;
    MITScannerOverlayView *overlay = [[MITScannerOverlayView alloc] initWithFrame:frame];
    overlay.backgroundColor = [UIColor clearColor];
    overlay.userInteractionEnabled = NO;
    overlay.autoresizingMask = UIViewAutoresizingNone;
    if ([self.scannerMgr isScanningSupported]) {
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
        
        if ([self.scannerMgr isScanningSupported])
        {
            self.scannerMgr.previewLayer.frame = scannerContentBounds;
            [self.scanView.layer insertSublayer:self.scannerMgr.previewLayer atIndex:0];
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

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self.scannerMgr isScanningSupported])
    {
        UIBarButtonItem *toolbarItem = [[UIBarButtonItem alloc] initWithTitle:@"History"
                                                                        style:UIBarButtonItemStyleBordered
                                                                       target:self
                                                                       action:@selector(showHistory:)];
        self.navigationItem.rightBarButtonItem = toolbarItem;
    }
    
    self.navigationController.toolbarHidden = YES;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
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
    
    [self.scannerMgr startSessionCapture];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.scannerMgr stopSessionCapture];
    
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
    if( [self isOnIpad] )
    {
        return UIInterfaceOrientationMaskAll;
    }
    
    return UIInterfaceOrientationMaskPortrait;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.overlayView setNeedsDisplay];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.scannerMgr setVideoOrientation];
}

- (IBAction)showHistory:(id)sender
{
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
    
    MITScannerHistoryViewController *historyVC = [MITScannerHistoryViewController new];
    [self.navigationController pushViewController:historyVC animated:YES];
}

- (void)prepareForShowingHistoryOnIpad
{
    [self.scannerMgr stopSessionCapture];
    [self removeVisibleScanningAlerts];
    [self.scannerHistory resetHistoryNewScanCounter];
    [self updateHistoryButtonTitle];
    
    if( [self.advancedMenuPopover isPopoverVisible] )
    {
        [self.advancedMenuPopover dismissPopoverAnimated:NO];
    }
}

- (void)showHistoryOnIpad
{
    [self prepareForShowingHistoryOnIpad];
    
    MITNavigationController *navController = [[MITNavigationController alloc] initWithRootViewController:[MITScannerHistoryViewController new]];
    self.historyPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    self.historyPopoverController.delegate = self;
    [self.historyPopoverController setPopoverContentSize:CGSizeMake(400, 480) animated:NO];
    [self.historyPopoverController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem
                                          permittedArrowDirections:UIPopoverArrowDirectionUp
                                                          animated:YES];
}

- (void)showDetailsThroughHistoryForItemWithIndex:(NSInteger)itemIndex
{
    [self prepareForShowingHistoryOnIpad];
    
    MITScannerHistoryViewController *historyVC = [MITScannerHistoryViewController new];
    historyVC.itemToOpenOnLoadIndex = itemIndex;
    MITNavigationController *navController = [[MITNavigationController alloc] initWithRootViewController:historyVC];
    self.historyPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    self.historyPopoverController.delegate = self;
    [self.historyPopoverController setPopoverContentSize:CGSizeMake(400, 480) animated:NO];
    [self.historyPopoverController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem
                                          permittedArrowDirections:UIPopoverArrowDirectionUp
                                                          animated:YES];
}

- (IBAction)showHelp:(id)sender
{
    [self.scannerMgr stopSessionCapture];
    
    MITScannerHelpViewController *vc = [[MITScannerHelpViewController alloc] init];
    vc.delegate = self;
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
    NSInteger newScanCounter = [self.scannerHistory historyNewScanCounter];

    self.navigationItem.rightBarButtonItem.title = [self historyTitleWithNumberOfRecentScans:newScanCounter];
}

#pragma mark - Scanning Methods

- (void)showScanDetailsForScanResult:(QRReaderResult *)result
{
    if( [self isOnIpad] )
    {
        [self showDetailsThroughHistoryForItemWithIndex:0];
        
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

- (BOOL)isOnIpad
{
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

- (void)runAsyncOnMainThread:(dispatch_block_t) blockToRun
{
    dispatch_async(dispatch_get_main_queue(), blockToRun);
}

- (void)runAsyncOnBackgroundThread:(dispatch_block_t) blockToRun
{
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), blockToRun );
}

@end

#pragma mark - ScanDetailViewDelegate

@implementation MITScannerViewController(ScanDetailViewDelegate)

- (void)detailFormSheetViewDidDisappear
{
    [self.scannerMgr startSessionCapture];
    self.overlayView.hidden = NO;
}

@end

@implementation MITScannerViewController(BatchScanAlertHandler)

- (void)showAlertForScanResult:(QRReaderResult *)result
{
    double fadingDuration = 2.0;
    double waitBeforeFading = 4.0;
    
    [self runAsyncOnMainThread:^{
        
        __block MITBatchScanningAlertView *firstAlert = (MITBatchScanningAlertView *)[self.view viewWithTag:FIRST_ALERT_POSITION_TAG];
        __block MITBatchScanningAlertView *secondAlert = (MITBatchScanningAlertView *)[self.view viewWithTag:SECOND_ALERT_POSITION_TAG];
        
        if( firstAlert == nil )
        {
            firstAlert = [self alertWithScanResult:result];
            firstAlert.tag = FIRST_ALERT_POSITION_TAG;
            [self.view addSubview:firstAlert];
            
            [firstAlert fadeOutWithDuration:fadingDuration andWait:waitBeforeFading completion:^{
                [firstAlert removeFromSuperview];
                firstAlert = nil;
            }];
        }
        else
        {
            // if second alert is already created, then need to remove it
            // as we shift everything down.
            if( secondAlert != nil )
            {
                [secondAlert removeFromSuperview];
                secondAlert = nil;
            }
            
            // moving first alert down on a second position
            CGRect alertFrame = firstAlert.frame;
            alertFrame.origin.y += alertFrame.size.height + 5;
            firstAlert.frame = alertFrame;
            firstAlert.tag = SECOND_ALERT_POSITION_TAG;
            
            // creating another alert and setting it to the first position
            secondAlert = [self alertWithScanResult:result];
            secondAlert.tag = FIRST_ALERT_POSITION_TAG;
            [self.view addSubview:secondAlert];
            
            // animating fade animation for that other alert we just created
            [secondAlert fadeOutWithDuration:fadingDuration andWait:waitBeforeFading completion:^{
                [secondAlert removeFromSuperview];
                secondAlert = nil;
            }];
        }
    }];
}

- (MITBatchScanningAlertView *)alertWithScanResult:(QRReaderResult *)result
{
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([MITBatchScanningAlertView class]) bundle:nil];
    MITBatchScanningAlertView *alertView = [nib instantiateWithOwner:nil options:nil][0];
    alertView.scanCodeLabel.text = result.text;
    alertView.ScanThumbnailView.image = result.thumbnail;
    alertView.scanId = result.objectID;
    alertView.delegate = self;
    
    return alertView;
}

- (void)didTouchAlertView:(MITBatchScanningAlertView *)alertView
{
    NSInteger index = (alertView.tag == FIRST_ALERT_POSITION_TAG) ? 0 : 1;
    [self showDetailsThroughHistoryForItemWithIndex:index];
}

- (void)removeVisibleScanningAlerts
{
    MITBatchScanningAlertView *firstAlert = (MITBatchScanningAlertView *)[self.view viewWithTag:FIRST_ALERT_POSITION_TAG];
    [firstAlert removeFromSuperview];
    firstAlert = nil;
    
    MITBatchScanningAlertView *secondAlert = (MITBatchScanningAlertView *)[self.view viewWithTag:SECOND_ALERT_POSITION_TAG];
    [secondAlert removeFromSuperview];
    secondAlert = nil;
}

@end

@implementation MITScannerViewController(DelegatesHandler)

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self runAsyncOnMainThread:^{
        self.overlayView.highlighted = NO;
        [self updateHistoryButtonTitle];
        [self.scannerMgr startSessionCapture];
    }];
}

- (void)helpViewControllerDidClose
{
    [self.scannerMgr startSessionCapture];
}

- (void)barCodeFound
{
    [self runAsyncOnMainThread:^{
        self.overlayView.highlighted = YES;
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }];
}

- (void)barCodeProcessed:(QRReaderResult *)result isBatchScanning:(BOOL)isBatchScanning
{
    [self runAsyncOnMainThread:^{        

        if ( isBatchScanning )
        {
            [self.scannerHistory updateHistoryNewScanCounter];
            [self updateHistoryButtonTitle];
            
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
    }];
}

- (void)continueBatchScanning
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        self.overlayView.highlighted = NO;
        
        if( ![self.historyPopoverController isPopoverVisible] )
        {
            [self.scannerMgr startSessionCapture];
        }
    });
}

@end
