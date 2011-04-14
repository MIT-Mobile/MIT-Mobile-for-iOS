//
//  QRReaderScanViewController.m
//  MIT Mobile
//
//  Created by Blake Skinner on 4/6/11.
//  Copyright 2011 MIT. All rights reserved.
//

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

@interface QRReaderScanViewController ()
@property (nonatomic,retain) AVCaptureSession *captureSession;
@property (nonatomic,retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic,retain) QRReaderOverlayView *overlayView;
@property (nonatomic) BOOL isCaptureActive;
@property (nonatomic,retain) UIControl *cancelButton;

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
    
    UISegmentedControl *cancelButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@"Cancel"]];
    cancelButton.segmentedControlStyle = UISegmentedControlStyleBar;
    cancelButton.tintColor = [UIColor grayColor];
    cancelButton.momentary = YES;
    [cancelButton addTarget:self
                     action:@selector(cancelScan:)
           forControlEvents:UIControlEventValueChanged];
    cancelButton.layer.cornerRadius = 5.0;
    self.cancelButton = cancelButton;
    [cancelButton release];
    
    self.cancelButton.frame = CGRectMake(103, 415, 115, 34);
    _decodedResult = NO;
}

- (void)dealloc
{
    self.captureSession = nil;
    self.cancelButton = nil;
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
    
    [self.overlayView removeFromSuperview];
    [self.previewLayer removeFromSuperlayer];
    self.previewLayer = nil;
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
    
    CGImageRef cropped = CGImageCreateWithImageInRect(cgImage, [self.overlayView qrRect]);
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
    
    if (self.scanDelegate) {
        [self.scanDelegate scanView:self
                      didScanResult:result.text
                          fromImage:image];
    }
}
@end
