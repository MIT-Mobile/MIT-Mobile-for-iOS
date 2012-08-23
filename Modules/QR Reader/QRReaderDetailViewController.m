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
@property (strong) NSDictionary *scanShareDetails;
@property (strong) NSString *scanType;
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
@synthesize scanShareDetails = _scanShareDetails;

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
    
    if (self.scanResult.scanImage) {
        self.qrImageView.image = self.scanResult.scanImage;
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

- (void)viewWillAppear:(BOOL)animated {
    self.loadingView.hidden = NO;
    self.navigationController.navigationBar.translucent = NO;
    
    // Check for any available code => URL mappings from
    // the mobile server
    {
        
        NSMutableDictionary *params = [NSDictionary dictionaryWithObject:self.scanResult.text
                                                                  forKey:@"q"];
        MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"qr"
                                                                                command:nil
                                                                             parameters:params];
        
        operation.completeBlock = ^(MobileRequestOperation *operation, NSDictionary *codeInfo, NSError *error)
        {
            [self handleScanInfoResponse:codeInfo
                                   error:error];
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

- (void)handleScanInfoResponse:(NSDictionary*)codeInfo error:(NSError*)error
{
    BOOL success = (error == nil) && [[codeInfo objectForKey:@"success"] boolValue];
    
    NSArray *actions = [codeInfo objectForKey:@"actions"];
    BOOL validResponse = actions && [actions isKindOfClass:[NSArray class]];
    
    if (success && validResponse)
    {
        [self.scanActions removeAllObjects];
        for (NSDictionary *action in actions)
        {
            if ([action isKindOfClass:[NSDictionary class]] == NO)
            {
                validResponse = NO;
                break;
            }
            else
            {
                [self.scanActions addObject:action];
            }
        }
        
        if (validResponse)
        {
            self.scanShareDetails = [codeInfo objectForKey:@"share"];
            self.textTitleLabel.text = [codeInfo objectForKey:@"displayType"];
            self.textView.text = [codeInfo objectForKey:@"displayName"];
            self.scanType = [codeInfo objectForKey:@"type"];
        }
    }
    
    if (validResponse == NO)
    {
        DLog(@"Did not recieve a valid action response from the server for code '%@'", self.scanResult.text);
        
        [self.scanActions removeAllObjects];
        NSURL *url = [NSURL URLWithString:self.scanResult.text];
        if ([[UIApplication sharedApplication] canOpenURL:url])
        {
            self.scanShareDetails = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Share URL", self.scanResult.text, nil]
                                                            forKeys:[NSArray arrayWithObjects:@"title",@"data", nil]];
            [self.scanActions addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Open URL", self.scanResult.text, nil]
                                                                    forKeys:[NSArray arrayWithObjects:@"title",@"url", nil]]];
            self.scanType = @"url";
            self.textTitleLabel.text = @"URL";
            self.textView.text = self.scanResult.text;
        }
        else
        {
            self.scanShareDetails = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Share data", self.scanResult.text, nil]
                                                                forKeys:[NSArray arrayWithObjects:@"title",@"data", nil]];
            self.scanType = @"other";
            self.textTitleLabel.text = @"Other";
            self.textView.text = self.scanResult.text;
        }
    }
    CGSize boundingSize = CGSizeMake(CGRectGetWidth(self.textView.frame), CGFLOAT_MAX);
    CGSize requiredSize = [self.textView.text sizeWithFont:self.textView.font
                                                constrainedToSize:boundingSize
                                                lineBreakMode:UILineBreakModeWordWrap];
    CGFloat requiredHeight = requiredSize.height;
    
    CGFloat padding = 15.0;
    CGRect textFrame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, requiredSize.width, requiredHeight);
    CGRect tableFrame = self.scanActionTable.frame;

    tableFrame.origin.y = CGRectGetMaxY(textFrame) + padding;
    
    self.textView.frame = textFrame;
    self.scanActionTable.frame = tableFrame;
    
    self.dateLabel.text = [NSString stringWithFormat:@"Scanned %@", [NSDateFormatter relativeDateStringFromDate:self.scanResult.date
                                                                                                         toDate:[NSDate date]]];
    [self.scanActionTable reloadData];
    self.loadingView.hidden = YES;
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, CGRectGetMaxY(self.scanActionTable.frame) + padding);
}

#pragma mark -
#pragma mark IBAction methods
- (IBAction)pressedShareButton:(id)sender {
    if (self.scanShareDetails)
    {
        self.shareDelegate = self;
        [self share:self];
    }
}

- (IBAction)pressedActionButton:(id)sender {
    NSString *altURL = self.resultText;
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:altURL]];
}

#pragma mark -
#pragma mark ShareItemDelegate (MIT)
- (NSString *)actionSheetTitle {
	return [self.scanShareDetails objectForKey:@"data"];
}

- (NSString *)emailSubject {
	return self.textView.text;
}

- (NSString *)emailBody {
	return [NSString stringWithFormat:@"I thought you might be interested in this %@...\n\n%@", [self.scanType lowercaseString], self.textView.text];
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
			@"MIT scan result",
            self.textView.text,
            self.textTitleLabel.text];
}

- (NSString *)twitterUrl {
    return self.textView.text;
}

- (NSString *)twitterTitle {
	return self.scanResult.text;
}

                 
#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.row < [self.scanActions count])
    {
        NSDictionary *cellDetails = [self.scanActions objectAtIndex:indexPath.row];
        NSURL *url = [NSURL URLWithString:[cellDetails objectForKey:@"url"]];
        
        if ([[UIApplication sharedApplication] canOpenURL:url])
        {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
    else if (self.scanShareDetails)
    {
        self.shareDelegate = self;
        [self share:self];
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
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:actionCellIdentifier] autorelease];
    }
    
    
    if (indexPath.row < [self.scanActions count])
    {
        NSDictionary *cellDetails = [self.scanActions objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [cellDetails objectForKey:@"title"];
        cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"global/action-external"]
                                               highlightedImage:[UIImage imageNamed:@"global/action-external-highlight"]] autorelease];
    }
    else
    {
        cell.textLabel.text = [self.scanShareDetails objectForKey:@"title"];
        cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"global/action-share"]] autorelease];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int count = [self.scanActions count];
    count += [self.scanShareDetails count] ? 1 : 0;
    return count;
}
@end
