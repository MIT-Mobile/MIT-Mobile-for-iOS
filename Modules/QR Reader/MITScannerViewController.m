#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "MITScannerViewController.h"
#import "MITScannerOverlayView.h"
#import "ZBarSDK.h"
#import "QRReaderHistoryData.h"
#import "QRReaderDetailViewController.h"
#import "UIKit+MITAdditions.h"
#import "QRReaderResult.h"
#import "NSDateFormatter+RelativeString.h"
#import "MITScannerHelpViewController.h"
#import "UIImage+Resize.h"
#import "CoreDataManager.h"

@interface MITScannerViewController () <ZBarReaderViewDelegate,UITableViewDelegate,UITableViewDataSource,NSFetchedResultsControllerDelegate>

#pragma mark - Scanner Properties
@property (strong) UIView *scanView;
@property (weak) UIView *unsupportedView;
@property (weak) MITScannerOverlayView *overlayView;
@property (weak) ZBarReaderView *readerView;
@property (weak) UIButton *infoButton;

@property (nonatomic,assign) BOOL isCaptureActive;
@property (readonly) BOOL isScanningSupported;

#pragma mark - History Properties
@property (strong) UIView *historyView;
@property (weak) UITableView *historyTableView;
@property (strong) QRReaderHistoryData *scannerHistory;

@property (strong) NSManagedObjectContext *fetchContext;
@property (strong) NSFetchedResultsController *fetchController;
@property (strong) NSOperationQueue *renderingQueue;

#pragma mark - Private methods
- (IBAction)showHistory:(id)sender;
- (IBAction)showScanner:(id)sender;
- (IBAction)showHelp:(id)sender;

- (void)startCapture;
- (void)stopCapture;

- (UIView*)loadScannerViewWithFrame:(CGRect)viewFrame;
- (UIView*)loadHistoryViewWithFrame:(CGRect)viewFrame;

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;
@end
#pragma mark -

@implementation MITScannerViewController
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
        
        
        self.renderingQueue = [[NSOperationQueue alloc] init];
        self.renderingQueue.maxConcurrentOperationCount = 1;
        
        
        NSManagedObjectContext *fetchContext = [[NSManagedObjectContext alloc] init];
        fetchContext.persistentStoreCoordinator = [[CoreDataManager coreDataManager] persistentStoreCoordinator];
        fetchContext.undoManager = nil;
        fetchContext.stalenessInterval = 0;
        
        self.scannerHistory = [[QRReaderHistoryData alloc] initWithManagedContext:fetchContext];
        self.fetchContext = fetchContext;
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"QRReaderResult"
                                                  inManagedObjectContext:fetchContext];
        NSSortDescriptor *dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date"
                                                                        ascending:NO];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        fetchRequest.entity = entity;
        fetchRequest.sortDescriptors = @[dateDescriptor];
        
        self.fetchController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:fetchContext
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:nil];
        self.fetchController.delegate = self;
    }
    return self;
}

- (BOOL)wantsFullScreenLayout
{
    return YES;
}

- (void)dealloc
{
    [self.renderingQueue cancelAllOperations];
}

- (void)loadView
{
    CGFloat navBarHeight = (self.navigationController.navigationBarHidden ?
                            0.0 :
                            CGRectGetHeight(self.navigationController.navigationBar.frame));
    
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    UIView *mainView = [[UIView alloc] initWithFrame:frame];
    mainView.backgroundColor = [UIColor blackColor];
    self.view = mainView;
    
    mainView.autoresizesSubviews = YES;
    mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleBottomMargin);
    
    self.scanView = [self loadScannerViewWithFrame:mainView.bounds];
    [mainView addSubview:self.scanView];
    
    if (self.isScanningSupported)
    {
        CGRect historyFrame = mainView.bounds;
        historyFrame.origin.y += navBarHeight;
        historyFrame.size.height -= navBarHeight;
        self.historyView = [self loadHistoryViewWithFrame:historyFrame];
        self.historyView.hidden = YES;
        [mainView insertSubview:self.historyView
                   belowSubview:self.scanView];
    }
    
}

- (UIView*)loadScannerViewWithFrame:(CGRect)viewFrame
{
    BOOL scanningSupported = self.isScanningSupported;
    
    
    // Configures the container for the scanning views.
    //  This should be the size of the full screen
    //      since the toolbar should be set to the
    //      UIBarStyleBlack and the 'translucent' property
    //      should be YES
    UIView *scanView = [[UIView alloc] initWithFrame:viewFrame];
    scanView.backgroundColor = [UIColor blackColor];
    scanView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleBottomMargin);
    
    // View hierarchy for the scanView
    // This should be in the order (top-most view first):
    //  overlayView
    //  readerView
    
    {
        CGFloat navBarHeight = (self.navigationController.navigationBarHidden ?
                                0.0 :
                                CGRectGetHeight(self.navigationController.navigationBar.frame));
        
        CGRect overlayFrame = scanView.bounds;
        overlayFrame.origin.y += navBarHeight;
        overlayFrame.size.height -= navBarHeight;
        
        MITScannerOverlayView *overlay = [[MITScannerOverlayView alloc] initWithFrame:overlayFrame];
        overlay.userInteractionEnabled = NO;
        overlay.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                    UIViewAutoresizingFlexibleBottomMargin);
        if (scanningSupported)
        {
            overlay.helpText = @"To scan a QR code or barcode, frame it below.\nAvoid glare and shadows.";
        }
        else
        {
            overlay.helpText = @"A camera is required to scan QR codes and barcodes";
        }
        [scanView addSubview:overlay];
        
        self.overlayView = overlay;
    }
    
    {
        UIButton *info = [UIButton buttonWithType:UIButtonTypeInfoLight];
        [info addTarget:self
                 action:@selector(showHelp:)
       forControlEvents:UIControlEventTouchUpInside];
        
        CGRect frame = info.bounds;
        CGRect parentBounds = scanView.bounds;
        frame.origin.x = CGRectGetMaxX(parentBounds) - (CGRectGetWidth(frame) * 2.0);
        frame.origin.y = CGRectGetMaxY(parentBounds) - (CGRectGetHeight(frame) * 2.0);
        
        info.frame = frame;
        self.infoButton = info;
        [scanView insertSubview:info
                   aboveSubview:self.overlayView];
    }
    
    if (scanningSupported)
    {
        {
            ZBarReaderView *readerView = [[ZBarReaderView alloc] init];
            readerView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                           UIViewAutoresizingFlexibleWidth);
            readerView.frame = scanView.bounds;
            readerView.torchMode = AVCaptureTorchModeOff;
            readerView.readerDelegate = self;
            
            [scanView insertSubview:readerView
                       belowSubview:self.overlayView];
            self.readerView = readerView;
        }
    } else {
        UIImageView *unsupportedView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"qrreader/camera-unsupported"]];
        unsupportedView.backgroundColor = [UIColor clearColor];
        unsupportedView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                            UIViewAutoresizingFlexibleBottomMargin);
        CGRect cropRect = [scanView convertRect:self.overlayView.qrRect
                                       fromView:self.overlayView];
        CGRect frame = CGRectInset(cropRect,
                                   (CGRectGetWidth(cropRect) - unsupportedView.image.size.width) / 2.0,
                                   (CGRectGetHeight(cropRect) - unsupportedView.image.size.height) / 2.0);
        unsupportedView.frame = frame;
        [scanView addSubview:unsupportedView];
        self.unsupportedView = unsupportedView;
    }
    
    return scanView;
}

- (UIView*)loadHistoryViewWithFrame:(CGRect)viewFrame
{
    UIView *historyView = [[UIView alloc] initWithFrame:viewFrame];
    historyView.hidden = YES;
    
    // Setup the table view for viewing the history
    {
        UITableView *tableView = [[UITableView alloc] initWithFrame:historyView.bounds
                                                               style:UITableViewStylePlain];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.rowHeight = [QRReaderResult defaultThumbnailSize].height;
        self.historyTableView = tableView;
        [historyView addSubview:tableView];
    }
    
    return historyView;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.historyTableView) {
        [self.historyTableView deselectRowAtIndexPath:[self.historyTableView indexPathForSelectedRow] animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.scanView.hidden == NO)
    {
        [self startCapture];
    }
    else
    {
        [self.historyTableView reloadData];
    }
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.renderingQueue cancelAllOperations];
    NSError *saveError = nil;
    [self.fetchContext save:&saveError];
    if (saveError)
    {
        DDLogError(@"Error saving scan: %@", [saveError localizedDescription]);
    }
    
    [self stopCapture];
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
    [self stopCapture];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self.fetchController performFetch:nil];
    
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
         [self.historyTableView reloadData];
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
                        [self.fetchContext save:nil];
                    }];
}

- (IBAction)showHelp:(id)sender
{
    MITScannerHelpViewController *vc = [[MITScannerHelpViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self.navigationController presentModalViewController:vc
                                                 animated:YES];
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
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

- (void)readerView:(ZBarReaderView*)readerView
    didReadSymbols:(ZBarSymbolSet*)symbols
         fromImage:(UIImage*)image
{
    ZBarSymbol *readerSymbol = nil;
    
    // Grab the first symbol
    for(readerSymbol in symbols)
        break;
    
    if (readerSymbol)
    {
        self.navigationController.navigationBar.userInteractionEnabled = NO;
        [self stopCapture];
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        self.overlayView.highlighted = YES;
        
        QRReaderResult *result = [self.scannerHistory insertScanResult:readerSymbol.data
                                                              withDate:[NSDate date]
                                                             withImage:image];
        
        QRReaderDetailViewController *viewController = [QRReaderDetailViewController detailViewControllerForResult:result];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            [self.navigationController pushViewController:viewController
                                                 animated:YES];
            
            self.navigationController.navigationBar.userInteractionEnabled = YES;
            self.overlayView.highlighted = NO;
        });
    }
}

#pragma mark - History Methods
- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    QRReaderResult *result = [self.fetchController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = result.text;
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
    cell.detailTextLabel.text = [NSDateFormatter relativeDateStringFromDate:result.date
                                                                     toDate:[NSDate date]];
    
    if (result.thumbnail == nil)
    {
        CGRect imageFrame = cell.imageView.frame;
        imageFrame.size = [QRReaderResult defaultThumbnailSize];
        
        cell.imageView.frame = imageFrame;
        cell.imageView.contentMode = UIViewContentModeScaleToFill;
        cell.imageView.image = [UIImage imageNamed:@"news/news-placeholder.png"];
        cell.imageView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                           UIViewAutoresizingFlexibleWidth);
        
        UIImage *scanImage = result.scanImage;
        NSManagedObjectID *scanId = [result objectID];
        if (scanImage)
        {
            [self.renderingQueue addOperationWithBlock:^{
                UIImage *thumbnail = [scanImage resizedImage:[QRReaderResult defaultThumbnailSize]
                                        interpolationQuality:kCGInterpolationDefault];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    QRReaderResult *scan = (QRReaderResult*)([self.fetchContext objectWithID:scanId]);
                    
                    if (scan.isDeleted == NO)
                    {
                        scan.thumbnail = thumbnail;
                        [self.fetchContext save:nil];
                    }
                });
            }];
        }
    }
    else
    {
        CGRect frame = cell.imageView.frame;
        frame.size = result.thumbnail.size;
        cell.imageView.frame = frame;
        cell.imageView.image = result.thumbnail;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reusableCellId = @"HistoryCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableCellId];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:reusableCellId];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.textLabel.font = [UIFont fontWithName:cell.textLabel.font.fontName
                                              size:16.0];
    }
    
    [self configureCell:cell
            atIndexPath:indexPath];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    NSArray *sections = [self.fetchController sections];
    id<NSFetchedResultsSectionInfo> sectionInfo = sections[section];
    
    return [sectionInfo numberOfObjects];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Recently Scanned";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    QRReaderResult *result = [self.fetchController objectAtIndexPath:indexPath];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.scannerHistory deleteScanResult:result];
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    QRReaderResult *result = [self.fetchController objectAtIndexPath:indexPath];
    
    QRReaderDetailViewController *detailView = [QRReaderDetailViewController detailViewControllerForResult:result];
    [self.navigationController pushViewController:detailView
                                         animated:YES];
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    
    if (self.historyView.isHidden)
    {
        return;
    }
    
    UITableView *tableView = self.historyTableView;
    
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            break;
    }
}
@end
