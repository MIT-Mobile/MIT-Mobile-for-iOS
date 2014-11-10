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
#import "MITNavigationController.h"
#import "CoreDataManager.h"

@interface MITScannerViewController () <ZBarReaderViewDelegate,UITableViewDelegate,UITableViewDataSource,NSFetchedResultsControllerDelegate>

#pragma mark - Scanner Properties
@property (strong) UIView *scanView;
@property (weak) UIImageView *cameraUnavailableView;
@property (weak) MITScannerOverlayView *overlayView;
@property (weak) ZBarReaderView *readerView;
@property (weak) UIButton *infoButton;

@property (nonatomic,assign) BOOL isCaptureActive;
@property (readonly) BOOL isScanningSupported;

#pragma mark - History Properties
@property (nonatomic,weak) UITableView *historyView;
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

        NSSortDescriptor *dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date"
                                                                        ascending:NO];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"QRReaderResult"];
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
        ZBarReaderView *readerView = [[ZBarReaderView alloc] init];
        readerView.torchMode = AVCaptureTorchModeOff;
        readerView.readerDelegate = self;
        readerView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleWidth);

        [scannerView addSubview:readerView];
        self.readerView = readerView;
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


    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(showHelp:) forControlEvents:UIControlEventTouchUpInside];
    [scannerView addSubview:infoButton];
    self.infoButton = infoButton;


    [controllerView addSubview:scannerView];
    self.scanView = scannerView;
}

- (void)viewWillLayoutSubviews
{
    self.scanView.frame = self.view.bounds;
    {
        CGRect scannerContentBounds = self.scanView.bounds;
        if (self.isScanningSupported) {
            self.readerView.frame = scannerContentBounds;
        } else {
            CGRect cameraFrame = scannerContentBounds;
            cameraFrame.origin.y += 44.;
            self.cameraUnavailableView.frame = cameraFrame;
        }

        self.overlayView.frame = scannerContentBounds;

        CGRect frame = self.infoButton.bounds;
        frame.origin.x = CGRectGetMaxX(scannerContentBounds) - (CGRectGetWidth(frame) + 20.); //20px -> standard spacing between a view and it's superview
        frame.origin.y = CGRectGetMaxY(scannerContentBounds) - (CGRectGetHeight(frame) + 20.);
        self.infoButton.frame = frame;
    }

    if (self->_historyView) {
        CGRect historyFrame = self.view.bounds;
        historyFrame.origin.y = 64.;
        historyFrame.size.height -= 64.;
        self.historyView.frame = historyFrame;
    }
}

- (UIView*)historyView
{
    if (!_historyView) {
        CGRect historyFrame = self.view.bounds;
        historyFrame.origin.y = 64.;
        historyFrame.size.height -= 64.;
        UITableView *historyView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                                style:UITableViewStylePlain];
        historyView.delegate = self;
        historyView.dataSource = self;
        historyView.rowHeight = [QRReaderResult defaultThumbnailSize].height;

        [self.view addSubview:historyView];
        self.historyView = historyView;
    }

    return _historyView;
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.translucent = YES;
    
    // Directly access the ivar here so we don't trigger the lazy instantiation
    if (self->_historyView) {
        [self.historyView deselectRowAtIndexPath:[self.historyView indexPathForSelectedRow] animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.scanView.hidden == NO)
    {
        [self startCapture];
    }
    else
    {
        [self.historyView reloadData];
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
    // rely on Springboard to reset the navbar style to what it prefers
//    self.navigationController.navigationBar.translucent = NO;
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
         [self.historyView reloadData];
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
                        [self.historyView removeFromSuperview];
                        [self.fetchContext save:nil];
                    }];
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
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    cell.detailTextLabel.text = [NSDateFormatter relativeDateStringFromDate:result.date
                                                                     toDate:[NSDate date]];
    
    if (result.thumbnail == nil)
    {
        CGRect imageFrame = cell.imageView.frame;
        imageFrame.size = [QRReaderResult defaultThumbnailSize];
        
        cell.imageView.frame = imageFrame;
        cell.imageView.contentMode = UIViewContentModeScaleToFill;
        cell.imageView.image = [UIImage imageNamed:MITImageNewsImagePlaceholder];
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
    
    UITableView *tableView = self.historyView;
    
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
