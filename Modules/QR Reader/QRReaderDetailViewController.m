#import <QuartzCore/QuartzCore.h>

#import "QRReaderDetailViewController.h"
#import "QRReaderResult.h"
#import "MobileRequestOperation.h"
#import "MITLoadingActivityView.h"
#import "NSDateFormatter+RelativeString.h"

@interface QRReaderDetailViewController () <ShareItemDelegate>
@property (retain) NSString *resultText;
@property (retain) NSOperation *urlMappingOperation;
@property (assign) MITLoadingActivityView *loadingView;

#pragma mark - Public Properties
@property (retain) QRReaderResult *scanResult;

#pragma mark - Public IBOutlets
@property (assign) UIImageView *qrImageView;
@property (assign) UIImageView *backgroundImageView;
@property (assign) UILabel *textTitleLabel;
@property (assign) UITextView *textView;
@property (assign) UILabel *dateLabel;
@property (assign) UIButton *actionButton;
@property (assign) UIButton *shareButton;
#pragma mark -
@end

@implementation QRReaderDetailViewController
@synthesize scanResult = _scanResult;
@synthesize qrImageView = _qrImageView;
@synthesize actionButton = _actionButton;
@synthesize shareButton = _shareButton;
@synthesize backgroundImageView = _backgroundImageView;
@synthesize loadingView = _loadingView;
@synthesize resultText = _resultText;
@synthesize urlMappingOperation = _urlMappingOperation;
@synthesize textView = _textView;
@synthesize dateLabel = _dateLabel;
@synthesize textTitleLabel = _textTitleLabel;

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
    
    CGFloat inset = 0.0;
    CGFloat margin = 12.0;
    
    [self.actionButton setImage:[UIImage imageNamed:@"global/action-external"]
                      forState:UIControlStateNormal];
    [self.actionButton setImage:[UIImage imageNamed:@"global/action-external-highlighted"]
                      forState:UIControlStateHighlighted];
    
    inset = self.actionButton.frame.size.width - ([UIImage imageNamed:@"global/action-external"].size.width + margin);
    [self.actionButton setImageEdgeInsets:UIEdgeInsetsMake(0, inset, 0, 0)];
    
    [self.shareButton setImage:[UIImage imageNamed:@"global/action-share"]
                      forState:UIControlStateNormal];
    
    inset = self.shareButton.frame.size.width - ([UIImage imageNamed:@"global/action-share"].size.width + margin);
    [self.shareButton setImageEdgeInsets:UIEdgeInsetsMake(0, inset, 0, 0)];
    
    [self.actionButton setTitleEdgeInsets:UIEdgeInsetsMake(0, (-self.actionButton.frame.origin.x) + margin, 0, 0)];
    [self.shareButton setTitleEdgeInsets:UIEdgeInsetsMake(0, (-self.shareButton.frame.origin.x) + margin, 0, 0)];
    
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
    self.actionButton = nil;
    self.shareButton = nil;
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
            
            if ((success || url) && canHandleURL)
            {
                self.resultText = [url absoluteString];
                self.actionButton.hidden = NO;
                
                self.textTitleLabel.text = @"Website";
                [self.actionButton setTitle:@"Go to website"
                                   forState:UIControlStateNormal];
                [self.shareButton setTitle:@"Share this link"
                                  forState:UIControlStateNormal];
            }
            else
            {
                self.resultText = self.scanResult.text;
                
                self.actionButton.hidden = YES;
                self.textTitleLabel.text = @"Code";
                [self.shareButton setTitle:@"Share this code"
                                  forState:UIControlStateNormal];
            }
            
            self.textView.text = self.resultText;
            self.dateLabel.text = [NSString stringWithFormat:@"Scanned %@", [NSDateFormatter relativeDateStringFromDate:self.scanResult.date
                                                                       toDate:[NSDate date]]];
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
@end
