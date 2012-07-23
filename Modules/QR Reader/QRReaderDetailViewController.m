#import <QuartzCore/QuartzCore.h>

#import "QRReaderDetailViewController.h"
#import "QRReaderResult.h"
#import "MobileRequestOperation.h"
#import "MITLoadingActivityView.h"
#import "NSDateFormatter+RelativeString.h"

@interface QRReaderDetailViewController () <ShareItemDelegate,UITableViewDataSource,UITableViewDelegate>
@property (retain) NSString *resultText;
@property (retain) NSOperation *urlMappingOperation;
@property (assign) MITLoadingActivityView *loadingView;

#pragma mark - Public Properties
@property (retain) QRReaderResult *scanResult;

#pragma mark - Public IBOutlets
@property (assign) UIImageView *qrImageView;
@property (assign) UIImageView *backgroundImageView;
@property (assign) UILabel *textTitleLabel;
@property (assign) UILabel *textView;
@property (assign) UILabel *dateLabel;
@property (assign) UITableView *scanActionTable;
@property (strong) NSMutableArray *scanActions;
#pragma mark -
@end

@implementation QRReaderDetailViewController
@synthesize scanResult = _scanResult;
@synthesize qrImageView = _qrImageView;
@synthesize backgroundImageView = _backgroundImageView;
@synthesize loadingView = _loadingView;
@synthesize resultText = _resultText;
@synthesize urlMappingOperation = _urlMappingOperation;
@synthesize textView = _textView;
@synthesize dateLabel = _dateLabel;
@synthesize textTitleLabel = _textTitleLabel;
@synthesize scanActionTable = scanActionTable;
@synthesize scanActions = _scanActions;

+ (QRReaderDetailViewController*)detailViewControllerForResult:(QRReaderResult*)result {
    QRReaderDetailViewController *reader = [[self alloc] initWithNibName:@"QRReaderDetailViewController"
                                                                  bundle:nil];
    reader.scanResult = result;
    return [reader autorelease];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.scanResult = nil;
        self.title = @"Scan Detail";
        self.urlMappingOperation = nil;
    }
    return self;
}

- (void)dealloc
{
    self.resultText = nil;
    self.urlMappingOperation = nil;
    self.scanResult = nil;
    self.scanActions = nil;
    [super dealloc];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.backgroundImageView.image = [UIImage imageNamed:@"global/body-background"];
    
    if (self.scanResult.image) {
        self.qrImageView.image = self.scanResult.image;
    } else {
        self.qrImageView.image = [UIImage imageNamed:@"qrreader/qr-missing-image"];
    }

    self.scanActions = [NSMutableArray array];
    
    {
        CGRect loadingViewBounds = self.view.bounds;
        loadingViewBounds.origin.y += CGRectGetHeight(self.qrImageView.frame);
        loadingViewBounds.size.height -= CGRectGetHeight(self.qrImageView.frame);
        
        self.loadingView = [[[MITLoadingActivityView alloc] initWithFrame:loadingViewBounds] autorelease];
        self.loadingView.hidden = NO;
        [self.view addSubview:self.loadingView];
    }
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.loadingView = nil;
    self.qrImageView = nil;
    self.backgroundImageView = nil;
    self.textTitleLabel = nil;
    self.textView = nil;
    self.dateLabel = nil;
}

- (NSDictionary*)dictionaryWithTitle:(NSString*)title iconNamed:(NSString*)iconName action:(void(^)(void))actionBlock
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setObject:[[actionBlock copy] autorelease]
                   forKey:@"action"];
    [dictionary setObject:title
                   forKey:@"title"];

    if ([iconName length])
    {
        [dictionary setObject:iconName
                       forKey:@"icon-name"];
    }
    
    return dictionary;
}

- (void)viewWillAppear:(BOOL)animated {
    self.loadingView.hidden = NO;
    
    // Check for any available code => URL mappings from
    // the mobile server
    {
        NSURL *url = [NSURL URLWithString:self.scanResult.text];
        NSString *paramKey = @"barcode";
        if (url && [[UIApplication sharedApplication] canOpenURL:url])
        {
            paramKey = @"url";
        }
        
        NSMutableDictionary *params = [NSDictionary dictionaryWithObject:self.scanResult.text
                                                                  forKey:paramKey];
        MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"qr"
                                                                                command:@""
                                                                             parameters:params];
        
        operation.completeBlock = ^(MobileRequestOperation *operation, NSDictionary *codeInfo, NSError *error)
        {
            // TODO (bskinner): Make sure this is even needed and adjust the timing
            //
            // Prevent the loading view from 'flashing' when the view
            // first appears (caused by the operation completing VERY
            // quickly)
            [NSThread sleepForTimeInterval:1.0];
            
            BOOL success = [[codeInfo objectForKey:@"success"] boolValue] && (error == nil);
            NSURL *url = [NSURL URLWithString:[codeInfo objectForKey:@"url"]];
            
            if (url == nil)
            {
                url = [NSURL URLWithString:self.scanResult.text];
            }
            
            BOOL canHandleURL = [[UIApplication sharedApplication] canOpenURL:url];
            
            [self.scanActions removeAllObjects];
            
            if ((success || url) && canHandleURL)
            {
                self.textTitleLabel.text = @"Website";
                self.resultText = [url absoluteString];
                
                [self.scanActions addObject:[self dictionaryWithTitle:@"Go to website"
                                                      iconNamed:@"global/action-external"
                                                         action:^{
                                                             [self pressedActionButton:nil];
                                                         }]];
                
                [self.scanActions addObject:[self dictionaryWithTitle:@"Share this link"
                                                            iconNamed:@"global/action-share"
                                                               action:^{
                                                                   [self pressedShareButton:nil];
                                                               }]];
            }
            else
            {
                self.textTitleLabel.text = @"Code";
                self.resultText = self.scanResult.text;
                
                [self.scanActions addObject:[self dictionaryWithTitle:@"Share this code"
                                                            iconNamed:@"global/action-share"
                                                               action:^{
                                                                   [self pressedShareButton:nil];
                                                               }]];
            }
            
            self.textView.text = self.resultText;
            [self.textView sizeToFit];
            
            CGFloat padding = 15.0;
            CGRect textFrame = self.textView.frame;
            CGRect tableFrame = self.scanActionTable.frame;

            // The size of '85' is so that the table view has at least
            // 100 pixels of space. This number can probably be tweaked a bit
            // later on.
            textFrame.size.height = MIN(textFrame.size.height,85);
            tableFrame.origin.y = CGRectGetMaxY(textFrame) + padding;
            tableFrame.size.height = CGRectGetHeight(self.view.bounds) - tableFrame.origin.y;
            
            self.textView.frame = textFrame;
            self.scanActionTable.frame = tableFrame;
            
            self.dateLabel.text = [NSString stringWithFormat:@"Scanned %@", [NSDateFormatter relativeDateStringFromDate:self.scanResult.date
                                                                       toDate:[NSDate date]]];
            [self.scanActionTable reloadData];
            self.loadingView.hidden = YES;
        };
        
        self.urlMappingOperation = operation;
        [operation start];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.urlMappingOperation cancel];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark IBAction methods
- (IBAction)pressedShareButton:(id)sender {
    self.shareDelegate = self;
    [self share:self];
}

- (IBAction)pressedActionButton:(id)sender {
    NSString *altURL = self.resultText;
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:altURL]];
    
    // Bouncing to an internal link
    if ([altURL hasPrefix:@"mitmobile"]) {
        [self.navigationController setToolbarHidden:YES
                                           animated:YES];
    }
}


#pragma mark -
#pragma mark ShareItemDelegate (MIT)
- (NSString *)actionSheetTitle {
	return @"Share This Link";
}

- (NSString *)emailSubject {
	return [NSString stringWithFormat:@"%@", self.scanResult.text];
}

- (NSString *)emailBody {
	return [NSString stringWithFormat:@"I thought you might be interested in this link...\n\n%@", self.resultText];
}

- (NSString *)fbDialogPrompt {
	return nil;
}

- (NSString *)fbDialogAttachment {
	return [NSString stringWithFormat:
			@"{\"name\":\"%@\","
			"\"href\":\"%@\","
			"\"description\":\"%@\""
			"}",
			self.scanResult.text,
            self.resultText,
            @"MIT QR Code"];
}

- (NSString *)twitterUrl {
    return self.resultText;
}

- (NSString *)twitterTitle {
	return self.scanResult.text;
}

                 
#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *cellDetails = [self.scanActions objectAtIndex:indexPath.row];
    
    dispatch_block_t action = [cellDetails objectForKey:@"action"];
    if (action)
    {
        dispatch_async(dispatch_get_main_queue(), action);
    }
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}
                 
                 
#pragma mark - UITableViewDataSource
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *actionCellIdentifier = @"ActionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:actionCellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:actionCellIdentifier];
    }
    
    NSDictionary *cellDetails = [self.scanActions objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [cellDetails objectForKey:@"title"];
    
    NSString *iconName = [cellDetails objectForKey:@"icon-name"];
    if ([iconName length])
    {
        UIImage *icon = [UIImage imageNamed:iconName];
        UIImage *highlightIcon = [UIImage imageNamed:[NSString stringWithFormat:@"%@-highlight", iconName]];
        
        cell.accessoryView = [[UIImageView alloc] initWithImage:icon
                                               highlightedImage:highlightIcon];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.scanActions count];
}
@end
