#import <QuartzCore/QuartzCore.h>

#import "QRReaderHistoryViewController.h"

#import "QRReaderDetailViewController.h"
#import "QRReaderHelpView.h"
#import "QRReaderHistoryData.h"
#import "QRReaderResult.h"
#import "QRReaderScanViewController.h"
#import "NSDateFormatter+RelativeString.h"
#import "QRReaderResultTransform.h"


@interface QRReaderHistoryViewController ()
@property (nonatomic,retain) UIView *contentView;
@property (nonatomic,retain) QRReaderHelpView *helpView;
@property (nonatomic,retain) QRReaderScanViewController *scanController;
@property (nonatomic,retain) UITableView *tableView;

@end

@implementation QRReaderHistoryViewController
@synthesize tableView = _tableView;
@synthesize scanController = _scanController;
@synthesize helpView = _helpView;
@synthesize contentView = _contentView;

- (void)dealloc
{
    _history = nil;
    self.tableView = nil;
    self.scanController = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)loadView {
    self.title = @"QR Codes";
    self.view = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                  UIViewAutoresizingFlexibleWidth);
    
    _history = [QRReaderHistoryData sharedHistory];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup the toolbar in the root UIView
    {
        self.navigationController.toolbarHidden = NO;
        self.navigationController.toolbar.barStyle = UIBarStyleBlackOpaque;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoLight];
        [button addTarget:self
                   action:@selector(showHelp:)
         forControlEvents:UIControlEventTouchUpInside];
        _scanButton = button;
        
        UIBarButtonItem *cameraButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                       target:self
                                                                                       action:@selector(beginQRScanning:)] autorelease];
        
        if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            cameraButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                          target:nil
                                                                          action:nil] autorelease];
        }
        
        NSArray *toolItems = [NSArray arrayWithObjects:
                              [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                             target:nil
                                                                             action:nil] autorelease],
                              cameraButton,
                              [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                             target:nil
                                                                             action:nil] autorelease],
                              [[[UIBarButtonItem alloc] initWithCustomView:button] autorelease],
                              nil];
        
        UIBarButtonItem *item = nil;
        
        item = (UIBarButtonItem*)[toolItems objectAtIndex:0];
        [item setWidth:128.0];
        
        item = (UIBarButtonItem*)[toolItems objectAtIndex:1];
        [item setStyle:UIBarButtonItemStyleBordered];
        
        [self setToolbarItems:toolItems];
    }
    
    // Setup the content view
    {
        CGRect contentFrame = CGRectMake(0, 0, 320, 372);
        
        self.contentView = [[[UIView alloc] initWithFrame:contentFrame] autorelease];
        [self.view addSubview:self.contentView];
    }
    
    
    // Setup the table view for viewing the history
    {
        self.tableView = [[[UITableView alloc] initWithFrame:self.contentView.bounds
                                                       style:UITableViewStylePlain] autorelease];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        [self.contentView addSubview:self.tableView];
    }
    
    self.helpView = [[[QRReaderHelpView alloc] initWithFrame:self.contentView.bounds] autorelease];
    if ([_history.results count] == 0) {
        [self showHelp:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setToolbarHidden:NO
                                       animated:animated];
    if ([_history.results count] == 0) {
        [self showHelp:nil];
    } else {
        [self hideHelp:nil];
    }
    NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
    if (selectedRow) {
        [self.tableView deselectRowAtIndexPath:selectedRow animated:YES];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.contentView = nil;
    self.helpView = nil;
    self.tableView = nil;
    self.scanController = nil;
    _scanButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark IB Actions
- (IBAction)beginQRScanning:(id)sender {
    [self.navigationController popToViewController:self
                                          animated:YES];
    self.scanController = [[[QRReaderScanViewController alloc] init] autorelease];
    self.scanController.reader = [QRReaderScanViewController defaultReader];
    self.scanController.scanDelegate = self;
    
    [self presentModalViewController:self.scanController
                            animated:YES];
}

- (IBAction)showHelp:(id)sender {
    UIBarButtonItem *barButton = nil;
    
    if (sender) {
        barButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self
                                                                                    action:@selector(hideHelp:)] autorelease];
        barButton.style = UIBarButtonItemStyleDone;
    }

    if (!self.helpView) {
        self.helpView = [[[QRReaderHelpView alloc] initWithFrame:self.contentView.bounds] autorelease];
    }

    if (![self.helpView superview]) {
        [UIView transitionWithView:[self.navigationController topViewController].view
                          duration:(sender ? 1.0 : 0.0)
                           options:(sender ?
                                    UIViewAnimationOptionTransitionCurlUp :
                                    UIViewAnimationOptionTransitionNone)
                        animations:^{
                            _scanButton.alpha = 0.0;
                            [[self.navigationController topViewController].view addSubview:self.helpView];
                        }
                        completion:nil];

        if (sender) {
            [[self.navigationController topViewController].navigationItem setRightBarButtonItem:barButton
                                                                                       animated:(sender != nil)];
        }
    }
}

- (IBAction)hideHelp:(id)sender {
    if ([self.helpView superview]) {
        [[self.navigationController topViewController].navigationItem setRightBarButtonItem:nil
                                                                               animated:(sender != nil)];
        [UIView transitionWithView:[self.navigationController topViewController].view
                          duration:(sender ? 1.0 : 0.0)
                           options:(sender ?
                                    UIViewAnimationOptionTransitionCurlDown :
                                    UIViewAnimationOptionTransitionNone)
                        animations:^{
                            _scanButton.alpha = 1.0;
                            [self.helpView removeFromSuperview];
                        }
                        completion:nil];
    }
}

#pragma mark -
#pragma mark ScanView Delegate Methods
- (void)scanView:(QRReaderScanViewController*)scanView
   didScanResult:(NSString*)result
       fromImage:(UIImage*)image  {
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self scanViewDidCancel:scanView];
        [_history insertScanResult:result
                          withDate:[NSDate date]
                         withImage:image];
        
        if (self.helpView.superview == self.contentView) {
            [self hideHelp:nil];
        }
        
        [self.tableView reloadData];
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0
                                                                inSection:0]
                                    animated:NO
                              scrollPosition:UITableViewScrollPositionNone];
        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0
                                                                                  inSection:0]];
    });
}

- (void)scanViewDidCancel:(QRReaderScanViewController*)scanView {
    [self dismissModalViewControllerAnimated:YES];
    self.scanController = nil;
}

#pragma mark -
#pragma mark UITableViewDataSource Methods
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
    
    QRReaderResult *result = [_history.results objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [[QRReaderResultTransform sharedTransform] titleForScan:result.text];
    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.numberOfLines = 3;
    cell.detailTextLabel.text = [NSDateFormatter relativeDateStringFromDate:result.date
                                                                     toDate:[NSDate date]];
    cell.imageView.image = result.image;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_history.results count];
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
    QRReaderResult *result = [_history.results objectAtIndex:indexPath.row];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_history deleteScanResult:result];
        [tableView reloadData];
        
        if ([_history.results count] == 0) {
            [self showHelp:nil];
        }
    }
}

#pragma mark -
#pragma mark UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    QRReaderResult *result = [_history.results objectAtIndex:indexPath.row];
    QRReaderDetailViewController *detailView = [QRReaderDetailViewController detailViewControllerForResult:result];
    [detailView setToolbarItems:self.toolbarItems];
    [self.navigationController pushViewController:detailView
                                         animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 96.0;
}
@end
