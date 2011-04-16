#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#include <sys/types.h>
#include <sys/sysctl.h>

// MIT
#import "MITLogging.h"
#import "QRReaderOverlayView.h"
#import "QRReaderScanViewController.h"

// ZXing
#import "QRCodeReader.h"
#import "FormatReader.h"
#import "Decoder.h"
#import "TwoDDecoderResult.h"

#import "UIImage+Resize.h"

@interface QRReaderScanViewController ()
@property (nonatomic,retain) AVCaptureSession *captureSession;
@property (nonatomic,retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic,retain) QRReaderOverlayView *overlayView;
@property (nonatomic) BOOL isCaptureActive;
@property (nonatomic,retain) UIButton *cancelButton;

- (BOOL)startCapture;
- (void)stopCapture;
@end

@implementation QRReaderScanViewController
@synthesize captureSession = _captureSession;
@synthesize previewLayer = _previewLayer;
@synthesize overlayView = _overlayView;
@synthesize isCaptureActive = _isCaptureActive;
@synthesize reader = _reader;
@synthesize scanDelegate = _scanDelegate;
@synthesize cancelButton = _cancelButton;

+ (FormatReader*)defaultReader {
    return [[[QRCodeReader alloc] init] autorelease];
}

- (void)loadView {
    self.wantsFullScreenLayout = YES;
    self.view = [[[UIView alloc] init] autorelease];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                  UIViewAutoresizingFlexibleWidth);
    
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton setBackgroundImage:[UIImage imageNamed:@"global/bar-button-36"] forState:UIControlStateNormal];
    [self.cancelButton setTitle:@"Cancel"
                       forState:UIControlStateNormal];
    [self.cancelButton addTarget:self
                          action:@selector(cancelScan:)
                forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];

    _decodedResult = NO;
}

- (void)dealloc
{
    self.captureSession = nil;
    self.cancelButton = nil;
    self.overlayView = nil;
    self.previewLayer = nil;

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
    self.overlayView = [[[QRReaderOverlayView alloc] initWithFrame:self.view.bounds] autorelease];
    self.isCaptureActive = NO;
    
    [self startCapture];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self stopCapture];
    self.overlayView = nil;
    self.previewLayer = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark -
#pragma mark Private Methods
- (BOOL)startCapture {
    NSError *error = nil;
    AVCaptureDeviceInput *inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]
                                                                              error:&error];
    if (error) {
        return NO;
    } else if (self.isCaptureActive) {
        return NO;
    }
    
    _decodedResult = NO;
    
    AVCaptureVideoDataOutput *output = [[[AVCaptureVideoDataOutput alloc] init] autorelease];
    
    output.alwaysDiscardsLateVideoFrames = YES;
    
    dispatch_queue_t queue = dispatch_queue_create("decoderQueue", NULL);
    [output setSampleBufferDelegate:self
                              queue:queue];
    dispatch_release(queue);
     
    [output setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]
                                                         forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey]];
    
    self.captureSession = [[[AVCaptureSession alloc] init] autorelease];
    
    if (self.captureSession) {
        self.captureSession.sessionPreset = AVCaptureSessionPresetMedium;
        [self.captureSession addInput:inputDevice];
        [self.captureSession addOutput:output];
        
        self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
        self.previewLayer.frame = self.view.bounds;
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self.view.layer addSublayer:self.previewLayer];
        [self.captureSession startRunning];
        self.isCaptureActive = YES;
    }
    
    [self.view addSubview:self.overlayView];
    
    [self.cancelButton sizeToFit];
    self.cancelButton.center = CGPointMake(self.view.frame.size.width / 2.0, self.view.frame.size.height - 64.0);

    [self.view insertSubview:self.cancelButton
                aboveSubview:self.overlayView];
    
    return (self.captureSession != nil);
}

- (void)stopCapture {
    if (self.isCaptureActive == NO) {
        return;
    }
    
    [self.captureSession stopRunning];
    self.captureSession = nil;
    
    self.isCaptureActive = NO;
}

- (BOOL)hasVMCopyBug {
    size_t size = 0;
    sysctlbyname("hw.machine",
                 NULL, &size,
                 NULL, 0);
    
    char *mname = (char*)malloc(size);
    memset((void*)mname,'\0',size + 1);
    sysctlbyname("hw.machine",
                 mname, &size,
                 NULL, 0);
    
    NSString *mstr = [NSString stringWithCString:mname
                                        encoding:NSASCIIStringEncoding];
    free(mname);
    
    return ([mstr isEqualToString:@"iPhone1,1"] ||
            [mstr isEqualToString:@"iPhone1,2"]);
}

- (void)cancelScan:(id)sender {
    if (self.scanDelegate) {
        [self.scanDelegate scanViewDidCancel:self];
    }
    
    [self stopCapture];
}

#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput*)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if ((self.isCaptureActive == NO) ||
        (self.reader == nil) ||
        _decodedResult)
    {
        [pool drain];
        return;
    }
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    void *bufferBase = NULL;
    BOOL mustFreeBuffer = NO;
    
    
    if ([self hasVMCopyBug]) {
        // vm_copy fails with the iPhone 3G series so, in order to avoid
        // flooding the log, we need to malloc, copy and free our own
        // copy of the pixel data.
        mustFreeBuffer = YES;
        size_t size = CVPixelBufferGetDataSize(imageBuffer);
        bufferBase = malloc(size);
        memcpy(bufferBase,CVPixelBufferGetBaseAddress(imageBuffer),size);
    } else {
        bufferBase = (void*)CVPixelBufferGetBaseAddress(imageBuffer);
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(bufferBase,
                                                 width,
                                                 height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
    
    if (context == nil) {
        if (mustFreeBuffer)
            free(bufferBase);
        
        if (imageBuffer)
            CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        
        [pool drain];
        return;
    }
    
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    CGRect clipRect = [self.overlayView qrRect];
    clipRect = [self.previewLayer convertRect:clipRect
                                    fromLayer:self.overlayView.layer];
    
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
    CGImageRelease(cgImage);
    CGImageRelease(cropped);
    
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    if (mustFreeBuffer)
        free(bufferBase);
    
    Decoder *decoder = [[[Decoder alloc] init] autorelease];
    decoder.readers = [NSArray arrayWithObject:_reader];
    decoder.delegate = self;
    
    _decodedResult = [decoder decodeImage:qrImage];
    
    [pool drain];
}

#pragma mark -
#pragma mark DecoderDelegate (ZXing)
- (void)decoder:(Decoder *)decoder
 didDecodeImage:(UIImage *)image
    usingSubset:(UIImage *)subset
     withResult:(TwoDDecoderResult *)result {
    self.overlayView.highlightColor = [UIColor greenColor];
    self.overlayView.highlighted = YES;
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    [self stopCapture];
    
    UIImage *rotateImage = [UIImage imageWithCGImage:[image CGImage]
                                               scale:1.0
                                         orientation:UIImageOrientationRight];

    rotateImage = [rotateImage resizedImage:image.size
                       interpolationQuality:kCGInterpolationDefault];
    
    if (self.scanDelegate) {
        [self.scanDelegate scanView:self
                      didScanResult:[NSString stringWithString:result.text]
                          fromImage:rotateImage];
    }
}
@end
