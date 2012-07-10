#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#include <sys/types.h>
#include <sys/sysctl.h>

// MIT
#import "QRReaderOverlayView.h"
#import "QRReaderScanViewController.h"

#import "UIImage+Resize.h"
#import "MobileRequestOperation.h"

@interface QRReaderScanViewController ()
@property (nonatomic,retain) QRReaderOverlayView *overlayView;
@property (nonatomic,retain) UILabel *adviceLabel;
@property (nonatomic) BOOL isCaptureActive;
@property (nonatomic,retain) UIButton *cancelButton;

- (BOOL)startCapture;
- (void)stopCapture;
@end

@implementation QRReaderScanViewController
@synthesize overlayView = _overlayView;
@synthesize adviceLabel;
@synthesize isCaptureActive = _isCaptureActive;
@synthesize scanDelegate = _scanDelegate;
@synthesize cancelButton = _cancelButton;
@synthesize qrcodeImage;

- (void)dealloc
{
    self.cancelButton = nil;
    self.overlayView = nil;
    self.qrcodeImage = nil;

    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    _readerView = [ZBarReaderViewController new].readerView;
    _readerView.readerDelegate = self;
    _readerView.frame = self.view.bounds;
    self.view = _readerView;
    self.overlayView = [[[QRReaderOverlayView alloc] initWithFrame:self.view.bounds] autorelease];
    self.isCaptureActive = NO;
    self.wantsFullScreenLayout = YES;
    self.view.backgroundColor = [UIColor blackColor];
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                  UIViewAutoresizingFlexibleWidth);
    
    self.adviceLabel = [[[UILabel alloc] init] autorelease];
    self.adviceLabel.backgroundColor = [UIColor clearColor];
    self.adviceLabel.textColor = [UIColor whiteColor];
    self.adviceLabel.textAlignment = UITextAlignmentCenter;
    self.adviceLabel.text = @"Frame a QR code to scan it.\nAvoid glare and shadows.";
    self.adviceLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.adviceLabel.numberOfLines = 0;
    
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton setBackgroundImage:[UIImage imageNamed:@"global/bar-button-36"] forState:UIControlStateNormal];
    [self.cancelButton setTitle:@"Cancel"
                       forState:UIControlStateNormal];
    [self.cancelButton addTarget:self
                          action:@selector(cancelScan:)
                forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    
    [self startCapture];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self stopCapture];
    self.overlayView = nil;
}


#pragma mark -
#pragma mark Private Methods
- (BOOL)startCapture {
    NSError *error = nil;
    AVCaptureDeviceInput *inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]        
                                                                              error:&error];
    if (inputDevice == nil) {
        if (error) {
            WLog(@"%@", [error localizedDescription]);
        }
        return NO;
    } else if (self.isCaptureActive) {
        return NO;
    }
    
    [_readerView addSubview:self.overlayView];
    [self.cancelButton sizeToFit];
    self.cancelButton.center = CGPointMake(self.view.frame.size.width / 2.0, self.view.frame.size.height - 60.0);

    [self.view insertSubview:self.cancelButton
                aboveSubview:self.overlayView];
    
    self.adviceLabel.frame = CGRectMake(0, 14.0, self.view.frame.size.width, 100.0);

    
    [self.view insertSubview:self.adviceLabel aboveSubview:self.overlayView];
    [_readerView start];
    return YES;
}

- (void)stopCapture {
    [_readerView stop];
    if (self.isCaptureActive == NO) {
        return;
    }
    self.isCaptureActive = NO;
}

- (void)cancelScan:(id)sender {
    if (self.scanDelegate) {
        [self.scanDelegate scanViewDidCancel:self];
    }
    
    [self stopCapture];
}


- (void) readerView: (ZBarReaderView*) areaderView
     didReadSymbols: (ZBarSymbolSet*) symbols
          fromImage: (UIImage*) image {    
    CGImageRef cgImage = image.CGImage;
    CGRect clipRect = [self.overlayView qrRect];
    CGFloat w_view = self.view.frame.size.width;
    CGFloat h_view = self.view.frame.size.height;
    CGFloat hRate = image.size.width / w_view;
    CGFloat vRate = image.size.height / h_view;
    CGFloat y_preview = hRate * clipRect.origin.y;
    CGFloat x_preview = vRate * clipRect.origin.x;
    clipRect = CGRectMake(x_preview, y_preview, clipRect.size.width * vRate, clipRect.size.height * vRate);
    
    // Fix the origin for the clipping rect as the video capture is 4:3
    // Will not work properly if the clipping rect is not centered on the
    // screen
    {
        CGFloat height = (CGFloat)CGImageGetHeight(cgImage);
        CGFloat width = (CGFloat)CGImageGetWidth(cgImage);
        
        clipRect.origin.x = (width - clipRect.size.width) / 2.0;
        clipRect.origin.y = (height - clipRect.size.height) / 2.0;
    }
    
    CGImageRef cropped = CGImageCreateWithImageInRect(cgImage, clipRect);
    UIImage *qrImage = [UIImage imageWithCGImage:cropped];
    
    self.overlayView.highlightColor = [UIColor greenColor];
    self.overlayView.highlighted = YES;
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    [self stopCapture];
    NSString *result = nil;
    for (ZBarSymbol *symbol in symbols) {
        result = symbol.data;
    }
    UIImage *rotateImage = [UIImage imageWithCGImage:[qrImage CGImage]
                                               scale:1.0
                                         orientation:UIImageOrientationRight];
    rotateImage = [rotateImage resizedImage:qrImage.size
                       interpolationQuality:kCGInterpolationDefault];
    
    [self checkQRCode:result fromImage:rotateImage];
}

- (NSString *)typeByEvaluateQRCodeResult:(NSString *)src {
    NSString *url = @"url";
    NSString *barcode = @"barcode";
    NSURL *nsurl = [NSURL URLWithString:src];
    if ([[UIApplication sharedApplication] canOpenURL:nsurl]) {
        return url;
    } else {
        return barcode;
    }
}

- (void)handleJsonResult:(id)jsonResult {
    NSString *qrcode = nil;
    NSDictionary *result = (NSDictionary *)jsonResult;
    if ([[result objectForKey:@"error"] boolValue]) {
        MobileRequestOperation *operation = [result objectForKey:@"operation"];
        qrcode = [[operation.parameters allValues] objectAtIndex:0];
    } else {
        NSDictionary *dic = [result objectForKey:@"result"];
        if ([[dic objectForKey:@"success"] boolValue]) {
            qrcode = [dic objectForKey:@"url"];
        } else {
            MobileRequestOperation *operation = [result objectForKey:@"operation"];
            qrcode = [[operation.parameters allValues] objectAtIndex:0];
        }
    }
    if (self.scanDelegate) {
        [self.scanDelegate scanView:self
                      didScanResult:[NSString stringWithString:qrcode]
                          fromImage:self.qrcodeImage];
    }
}

- (void)checkQRCode:(NSString *)qrcString fromImage:(UIImage *)image {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:qrcString forKey:[self typeByEvaluateQRCodeResult:qrcString]];
    MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"qr"
                                                                            command:@""
                                                                         parameters:params];
    self.qrcodeImage = image;
    __block QRReaderScanViewController *blockSelf = self;
    operation.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSError *error) {
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        [result setObject:operation forKey:@"operation"];
        [result setObject:[NSNumber numberWithBool:(error != nil)] forKey:@"error"];
        [result setObject:jsonResult ? jsonResult : @"" forKey:@"result"];
        [blockSelf performSelectorOnMainThread:@selector(handleJsonResult:) withObject:result waitUntilDone:YES];
    };
    [operation start];
}
@end
