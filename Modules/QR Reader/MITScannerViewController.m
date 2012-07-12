//
//  QRReaderViewController.m
//  MIT Mobile
//
//  Created by Blake Skinner on 7/2/12.
//
//

#import <AVFoundation/AVFoundation.h>

#import "MITScannerViewController.h"
#import "MITScannerOverlayView.h"
#import "ZBarSDK.h"
#import "QRReaderHistoryData.h"
#import "QRReaderDetailViewController.h"
#import "UIKit+MITAdditions.h"
#import "QRReaderResult.h"
#import "NSDateFormatter+RelativeString.h"

@interface MITScannerViewController () <ZBarReaderViewDelegate,UITableViewDelegate, UITableViewDataSource>

#pragma mark - Scanner Extensions
@property (retain) UIView *scanView;
@property (assign) UIView *unsupportedView;
@property (assign) MITScannerOverlayView *overlayView;
@property (assign) ZBarReaderView *readerView;

@property (nonatomic,assign) BOOL isCaptureActive;
@property (assign, readonly) BOOL isScanningSupported;

#pragma mark - History Extensions
@property (retain) UIView *historyView;
@property (assign) UITableView *historyTableView;
@property (retain) QRReaderHistoryData *historyEntries;

#pragma mark - Private methods
- (IBAction)showHistory:(id)sender;
- (IBAction)showScanner:(id)sender;

- (void)startCapture;
- (void)stopCapture;

- (UIView*)loadScannerViewWithFrame:(CGRect)viewFrame;
- (UIView*)loadHistoryViewWithFrame:(CGRect)viewFrame;
@end
#pragma mark -

@implementation MITScannerViewController
#pragma mark - Scanner Properties
@synthesize scanView = _scanView;
@synthesize unsupportedView = _unsupportedView;
@synthesize overlayView = _overlayView;
@synthesize isCaptureActive = _isCaptureActive;

@dynamic isScanningSupported;

#pragma mark - History Properties
@synthesize historyView = _historyView;
@synthesize historyTableView = _historyTableView;
@synthesize historyEntries = _historyEntries;

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
        self.historyEntries = [QRReaderHistoryData sharedHistory];
    }
    return self;
}

- (void)loadView
{
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    UIView *mainView = [[[UIView alloc] initWithFrame:frame] autorelease];
    mainView.backgroundColor = [UIColor blackColor];
    self.view = mainView;
    
    CGFloat navBarHeight = (self.navigationController.navigationBarHidden ?
                           0.0 :
                           CGRectGetHeight(self.navigationController.navigationBar.frame));
    
    if (self.isScanningSupported)
    {
        self.scanView = [self loadScannerViewWithFrame:mainView.bounds];
        
        CGRect historyFrame = mainView.bounds;
        historyFrame.origin.y += navBarHeight;
        historyFrame.size.height -= navBarHeight;
        self.historyView = [self loadHistoryViewWithFrame:historyFrame];
        self.historyView.hidden = YES;
        [mainView addSubview:self.scanView];
        [mainView insertSubview:self.historyView
                   belowSubview:self.scanView];
    }
    else
    {
        CGRect scanFrame = mainView.bounds;

        
        UIView *unsupportedView = [[[UIView alloc] initWithFrame:scanFrame] autorelease];
        unsupportedView.backgroundColor = [UIColor redColor];
        [mainView addSubview:unsupportedView];
        self.unsupportedView = unsupportedView;
    }

}

- (UIView*)loadScannerViewWithFrame:(CGRect)viewFrame
{
    UIView *resultView = nil;
    
    if (self.isScanningSupported)
    {
        // Configures the container for the scanning views.
        //  This should be the size of the full screen
        //      since the toolbar should be set to the
        //      UIBarStyleBlack and the 'translucent' property
        //      should be YES
        UIView *scanView = [[[UIView alloc] initWithFrame:viewFrame] autorelease];
        
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
            CGFloat navBarHeight = (self.navigationController.navigationBarHidden ?
                                    0.0 :
                                    CGRectGetHeight(self.navigationController.navigationBar.frame));
            
            CGRect overlayFrame = scanView.bounds;
            overlayFrame.origin.y += navBarHeight;
            overlayFrame.size.height -= navBarHeight;
            
            MITScannerOverlayView *overlay = [[[MITScannerOverlayView alloc] initWithFrame:overlayFrame] autorelease];
            overlay.userInteractionEnabled = NO;
            [scanView addSubview:overlay];
            
            CGRect cropRect = [self.readerView convertRect:[overlay qrRect]
                                                  fromView:overlay];
            
            self.readerView.scanCrop = CGRectNormalizeWithParentRect(cropRect, self.readerView.bounds);
            self.overlayView = overlay;
        }
        
        resultView = scanView;
    }

    return resultView;
}

- (UIView*)loadHistoryViewWithFrame:(CGRect)viewFrame
{
    UIView *historyView = [[[UIView alloc] initWithFrame:viewFrame] autorelease];

    // Setup the table view for viewing the history
    {
        UITableView *tableView = [[[UITableView alloc] initWithFrame:historyView.bounds
                                                               style:UITableViewStylePlain] autorelease];
        tableView.delegate = self;
        tableView.dataSource = self;
        [historyView addSubview:tableView];
    }

    return historyView;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.scanView.hidden == NO)
    {
        [self startCapture];
    }
    
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = NO;
    [self stopCapture];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.isScanningSupported)
    {
        UIBarButtonItem *toolbarItem = [[[UIBarButtonItem alloc] initWithTitle:@"History"
                                                                        style:UIBarButtonItemStyleBordered
                                                                       target:self
                                                                       action:@selector(showHistory:)] autorelease];
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
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [UIView transitionFromView:self.scanView
                        toView:self.historyView
                      duration:1.0
                       options:(UIViewAnimationOptionCurveEaseInOut |
                                UIViewAnimationOptionBeginFromCurrentState |
                                UIViewAnimationOptionShowHideTransitionViews |
                                UIViewAnimationOptionTransitionFlipFromRight)
                    completion:^(BOOL finished)
                    {
                        self.navigationItem.rightBarButtonItem.title = @"Scan";
                        [self.navigationItem.rightBarButtonItem setAction:@selector(showScanner:)];
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }];
}

- (IBAction)showScanner:(id)sender
{
    [self startCapture];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [UIView transitionFromView:self.historyView
                        toView:self.scanView
                      duration:1.0
                       options:(UIViewAnimationOptionCurveEaseInOut |
                                UIViewAnimationOptionBeginFromCurrentState |
                                UIViewAnimationOptionShowHideTransitionViews |
                                UIViewAnimationOptionTransitionFlipFromLeft)
                    completion:^(BOOL finished) {
                        self.navigationItem.rightBarButtonItem.title = @"History";
                        [self.navigationItem.rightBarButtonItem setAction:@selector(showHistory:)];
                        self.navigationItem.rightBarButtonItem.enabled = YES;
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
    ZBarSymbol *readerSymbol = nil;
    for( ZBarSymbol *symbol in symbols)
    {
        readerSymbol = symbol;
        break;
    }
    
    if (readerSymbol)
    {
        self.overlayView.highlighted = YES;
        QRReaderResult *result = [[QRReaderHistoryData sharedHistory] insertScanResult:readerSymbol.data
                                                                              withDate:[NSDate date]
                                                                             withImage:image];
        QRReaderDetailViewController *viewController = [QRReaderDetailViewController detailViewControllerForResult:result];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            [self.navigationController pushViewController:viewController
                                                 animated:YES];
            
            self.overlayView.highlighted = NO;
        }); 
    }
}

#pragma mark - History Methods
#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reusableCellId = @"HistoryCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableCellId];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:reusableCellId] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.textLabel.font = [UIFont fontWithName:cell.textLabel.font.fontName
                                              size:16.0];
    }

    QRReaderResult *result = [self.historyEntries.results objectAtIndex:indexPath.row];

    cell.textLabel.text = result.text;
    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.numberOfLines = 3;
    cell.detailTextLabel.text = [NSDateFormatter relativeDateStringFromDate:result.date
                                                                     toDate:[NSDate date]];
    cell.imageView.image = result.image;

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.historyEntries.results count];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Recently Scanned";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    QRReaderResult *result = [self.historyEntries.results objectAtIndex:indexPath.row];

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.historyEntries deleteScanResult:result];
        [tableView reloadData];

        if ([self.historyEntries.results count] == 0) {
            //[self showHelp:nil];
        }
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView
        didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    QRReaderResult *result = [self.historyEntries.results objectAtIndex:indexPath.row];
    QRReaderDetailViewController *detailView = [QRReaderDetailViewController detailViewControllerForResult:result];
    [detailView setToolbarItems:self.toolbarItems];
    [self.navigationController pushViewController:detailView
                                         animated:YES];
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 96.0;
}

@end
