//
//  QRReaderViewController.m
//  MIT Mobile
//
//  Created by Blake Skinner on 7/2/12.
//
//

#import <AVFoundation/AVFoundation.h>

#import "MITScannerViewController.h"
#import "QRReaderOverlayView.h"
#import "zbar.h"

@interface MITScannerViewController () <ZBarReaderViewDelegate>
#pragma mark - Scanner Extensions
@property (strong) UIView *scanView;
@property (strong) QRReaderOverlayView *overlayView;
@property (strong) ZBarReaderView *readerView;
@property (strong) UILabel *scanHelpLabel;

@property (nonatomic,assign) BOOL isCaptureActive;
@property (assign, readonly) BOOL isScanningSupported;

#pragma mark - History Extensions
@property (strong) UIView *historyView;

#pragma mark - Extension methods
- (IBAction)showHistory:(id)sender;
- (IBAction)showScanner:(id)sender;

- (void)startCapture;
- (void)stopCapture;
@end
#pragma mark -

@implementation MITScannerViewController
#pragma mark - Scanner Properties
@synthesize scanView = _scanView;
@synthesize overlayView = _overlayView;
@synthesize scanHelpLabel = _scanHelpLabel;
@synthesize isCaptureActive = _isCaptureActive;

@dynamic isScanningSupported;

#pragma mark - History Properties
@synthesize historyView = _historyView;

- (id)init
{
    return [self initWithNibName:nil
                          bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil
                           bundle:nil];
    if (self) {
        self.title = @"Scanner";
        self.isCaptureActive = NO;
    }
    return self;
}

- (void)loadView
{
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    UIView *mainView = [[[UIView alloc] initWithFrame:frame] autorelease];
    mainView.backgroundColor = [UIColor blueColor];
    self.view = mainView;
    
    if (self.isScanningSupported)
    {
        // Configures the container for the scanning views.
        //  This should be the size of the full screen
        //      since the toolbar should be set to the
        //      UIBarStyleBlack and the 'translucent' property
        //      should be YES
        CGRect scanFrame = mainView.bounds;
        UIView *scanView = [[[UIView alloc] initWithFrame:scanFrame] autorelease];
        
        scanView.backgroundColor = [UIColor blackColor];
        scanView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                     UIViewAutoresizingFlexibleWidth);
        
        // View hierarchy for the scanView
        // This should be in the order (top-most view first):
        //  scanHelpLabel
        //  overlayView
        //  readerView
        
        {
            ZBarReaderView *readerView = [[[ZBarReaderView alloc] init] autorelease];
            readerView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                         UIViewAutoresizingFlexibleWidth);
            readerView.frame = scanView.bounds;
            readerView.readerDelegate = self;
            [scanView addSubview:readerView];
            self.readerView = readerView;
        }
        
        {
            QRReaderOverlayView *overlay = [[[QRReaderOverlayView alloc] initWithFrame:scanView.bounds] autorelease];
            [scanView addSubview:overlay];
            self.readerView.scanCrop = [overlay normalizedCropRect];
            self.overlayView = overlay;
        }
        
        {
            CGRect overlayCrop = [self.overlayView qrRect];
            CGRect textFrame = CGRectZero;
            textFrame.size.width = CGRectGetWidth(scanView.bounds);
            textFrame.size.height = 44;
            textFrame.origin.y = (CGRectGetHeight(self.navigationController.navigationBar.frame) +
                                  ((overlayCrop.origin.y / 2.0) - textFrame.size.height ));
            textFrame.origin.x = 0;
            
            UILabel *textLabel = [[[UILabel alloc] initWithFrame:textFrame] autorelease];
            textLabel.backgroundColor = [UIColor clearColor];
            textLabel.textColor = [UIColor whiteColor];
            textLabel.textAlignment = UITextAlignmentCenter;
            textLabel.text = @"Frame a QR code to scan it.\nAvoid glare and shadows.";
            textLabel.lineBreakMode = UILineBreakModeWordWrap;
            textLabel.numberOfLines = 0;
            textLabel.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                          UIViewAutoresizingFlexibleWidth);
            
            
            [scanView insertSubview:textLabel
                       aboveSubview:self.overlayView];
            self.scanHelpLabel = textLabel;
        }
        
        self.scanView = scanView;
    }
    else
    {
        CGRect scanFrame = mainView.bounds;
        if (self.navigationController.navigationBarHidden == NO)
        {
            CGFloat navHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
            scanFrame.origin.y += navHeight;
            scanFrame.size.height -= navHeight;
        }
        
        UIView *unsupportedView = [[[UIView alloc] initWithFrame:scanFrame] autorelease];
        unsupportedView.backgroundColor = [UIColor redColor];
        self.scanView = unsupportedView;
    }
    
    [mainView addSubview:self.scanView];
    
    
    {
        CGRect historyFrame = mainView.bounds;
        if (self.navigationController.navigationBarHidden == NO)
        {
            CGFloat navHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
            historyFrame.origin.y += navHeight;
            historyFrame.size.height -= navHeight;
        }
        
        UIView *historyView = [[[UIView alloc] initWithFrame:historyFrame] autorelease];
        historyView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                        UIViewAutoresizingFlexibleBottomMargin |
                                        UIViewAutoresizingFlexibleWidth);
        historyView.backgroundColor = [UIColor lightGrayColor];
        historyView.hidden = YES;
        self.historyView = historyView;
        [mainView addSubview:historyView];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = NO;
    [self stopCapture];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self startCapture];
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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)showHistory:(id)sender
{
    [self stopCapture];
    
    [UIView transitionFromView:self.scanView
                        toView:self.historyView
                      duration:1.0
                       options:(UIViewAnimationOptionCurveEaseInOut |
                                UIViewAnimationOptionBeginFromCurrentState |
                                UIViewAnimationOptionShowHideTransitionViews |
                                UIViewAnimationOptionTransitionFlipFromRight)
                    completion:^(BOOL finished) {
                        UIBarButtonItem *toolbarItem = [[UIBarButtonItem alloc] initWithTitle:@"Scan"
                                                                                        style:UIBarButtonItemStyleBordered
                                                                                       target:self
                                                                                       action:@selector(showScanner:)];
                        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObject:toolbarItem]
                                                           animated:YES];
                    }];
}

- (IBAction)showScanner:(id)sender
{
    [self startCapture];
    
    [UIView transitionFromView:self.historyView
                        toView:self.scanView
                      duration:1.0
                       options:(UIViewAnimationOptionCurveEaseInOut |
                                UIViewAnimationOptionBeginFromCurrentState |
                                UIViewAnimationOptionShowHideTransitionViews |
                                UIViewAnimationOptionTransitionFlipFromLeft)
                    completion:^(BOOL finished) {
                        UIBarButtonItem *toolbarItem = [[UIBarButtonItem alloc] initWithTitle:@"History"
                                                                                        style:UIBarButtonItemStyleBordered
                                                                                       target:self
                                                                                       action:@selector(showHistory:)];
                        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObject:toolbarItem]
                                                           animated:YES];
                    }];
}

- (BOOL)isCaptureActive
{
    return (self->_isCaptureActive && self.isScanningSupported);
}

- (void)startCapture
{
    if (self.isCaptureActive == NO)
    {
        self.isCaptureActive = YES;
        [self.readerView start];
    }
}

- (void)stopCapture
{
    if (self.isCaptureActive)
    {
        self.isCaptureActive = NO;
        [self.readerView stop];
    }
}
#pragma mark - Scanning Methods
- (BOOL)isScanningSupported
{
    return [UIImagePickerController isCameraDeviceAvailable:(UIImagePickerControllerCameraDeviceFront |
                                                             UIImagePickerControllerCameraDeviceRear)];
}

- (void)readerView:(ZBarReaderView*)readerView
    didReadSymbols:(ZBarSymbolSet*)symbols
         fromImage:(UIImage*)image
{
    NSLog(@"Found %d symbol(s):", symbols.count);
    for(ZBarSymbol *symbol in symbols)
    {
        NSLog(@"\t'%@' [%@]", symbol.data, symbol.typeName);
    }
}
@end
