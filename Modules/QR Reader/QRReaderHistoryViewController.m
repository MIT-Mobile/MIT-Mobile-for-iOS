//
//  QRReaderHistoryViewController.m
//  MIT Mobile
//
//  Created by Blake Skinner on 4/6/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "QRReaderHistoryViewController.h"

#import "QRReaderDetailViewController.h"
#import "QRReaderHelpView.h"
#import "QRReaderHistoryData.h"
#import "QRReaderResult.h"
#import "QRReaderScanViewController.h"
#import "NSDateFormatter+RelativeString.h"

static NSString *QRReaderFirstVisitKey = @"QRReaderFirstVisit";

@interface QRReaderHistoryViewController ()
@property (nonatomic,retain) UIView *contentView;
@property (nonatomic,retain) QRReaderHelpView *helpView;
@property (nonatomic,retain) QRReaderScanViewController *scanController;
@property (nonatomic,retain) UITableView *tableView;
@property (nonatomic,retain) UIToolbar *toolbar;

@end

@implementation QRReaderHistoryViewController
@synthesize tableView = _tableView;
@synthesize scanController = _scanController;
@synthesize toolbar = _toolbar;
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
        self.toolbar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0,372,
                                                                    320,44)] autorelease];
        self.toolbar.barStyle = UIBarStyleBlackOpaque;
        
        NSArray *toolItems = [NSArray arrayWithObjects:
                              [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                             target:nil
                                                                             action:nil] autorelease],
                              [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                             target:self
                                                                             action:@selector(beginQRScanning:)] autorelease],
                              [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                             target:nil
                                                                             action:nil] autorelease],
                              nil];
        
        UIBarButtonItem *scan = (UIBarButtonItem*)[toolItems objectAtIndex:1];
        [scan setStyle:UIBarButtonItemStyleBordered];
        
        [self.toolbar setItems:toolItems];
        [self.view addSubview:self.toolbar];
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
    
    BOOL hereBefore = [[NSUserDefaults standardUserDefaults] boolForKey:QRReaderFirstVisitKey];

    if (hereBefore == NO) {
        // This is the user's first launch of the QRReader module
        [self showHelp:nil];
    } else {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoLight];
        [button addTarget:self
                   action:@selector(showHelp:)
         forControlEvents:UIControlEventTouchUpInside];
        [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:button] autorelease]
                                          animated:NO];
    }
    
    self.navigationItem.title = @"QR Codes";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    for (UIView *view in self.view.subviews) {
        [view removeFromSuperview];
    }
    
    self.contentView = nil;
    self.helpView = nil;
    self.tableView = nil;
    self.toolbar = nil;
    self.scanController = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark IB Actions
- (IBAction)beginQRScanning:(id)sender {
    self.scanController = [[[QRReaderScanViewController alloc] init] autorelease];
    self.scanController.reader = [QRReaderScanViewController defaultReader];
    self.scanController.scanDelegate = self;
    
    [self presentModalViewController:self.scanController
                            animated:YES];
}

- (IBAction)showHelp:(id)sender {
    UIBarButtonItem *barButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(hideHelp:)] autorelease];
    barButton.style = UIBarButtonItemStyleDone;
    
    [UIView transitionWithView:self.contentView
                      duration:(sender ? 1.0 : 0.0)
                       options:UIViewAnimationOptionTransitionCurlUp
                    animations:^{
                        [self.contentView insertSubview:self.helpView
                                           aboveSubview:self.tableView];
                    }
                    completion:nil];

    [self.navigationItem setRightBarButtonItem:barButton
                                      animated:(sender != nil)];
}

- (IBAction)hideHelp:(id)sender {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [button addTarget:self
               action:@selector(showHelp:)
     forControlEvents:UIControlEventTouchUpInside];
    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:button] autorelease]
                                      animated:(sender != nil)];
    
    [UIView transitionWithView:self.contentView
                      duration:(sender ? 1.0 : 0.0)
                       options:UIViewAnimationOptionTransitionCurlDown
                    animations:^{
                        [self.helpView removeFromSuperview];
                    }
                    completion:^(BOOL finished) {
                    }];
}

#pragma mark -
#pragma mark ScanView Delegate Methods
- (void)scanView:(QRReaderScanViewController*)scanView
   didScanResult:(NSString*)result
       fromImage:(UIImage*)image  {
    [self dismissModalViewControllerAnimated:YES];
    self.scanController = nil;
    
    [_history insertScanResult:result
                      withDate:[NSDate date]];
    
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
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    QRReaderResult *result = [_history.results objectAtIndex:indexPath.row];
    
    cell.textLabel.text = result.text;
    cell.detailTextLabel.text = [NSDateFormatter relativeDateStringFromDate:result.date
                                                                     toDate:[NSDate date]];
    
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

#pragma mark -
#pragma mark UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    QRReaderResult *result = [_history.results objectAtIndex:indexPath.row];
    QRReaderDetailViewController *detailView = [QRReaderDetailViewController detailViewControllerForResult:result];
    [self.navigationController pushViewController:detailView
                                         animated:YES];
}
@end
