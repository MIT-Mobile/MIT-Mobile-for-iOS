#import <QuartzCore/QuartzCore.h>

#import "QRReaderDetailViewController.h"
#import "QRReaderResult.h"
#import "MobileRequestOperation.h"
#import "MITLoadingActivityView.h"

@interface QRReaderDetailViewController () <ShareItemDelegate>
@property (nonatomic,retain) QRReaderResult *scanResult;
@property (retain) NSString *resultText;
@property (retain) MITLoadingActivityView *loadingView;
@property (retain) NSOperation *urlMappingOperation;
@property (nonatomic,assign) UIImageView *qrImageView;
@property (nonatomic,assign) UIImageView *backgroundImageView;
@property (nonatomic,assign) UITextView *textView;
@property (nonatomic,assign) UIButton *actionButton;
@property (nonatomic,assign) UIButton *shareButton;
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
    self.urlMappingOperation = nil;
    self.resultText = nil;
    self.scanResult = nil;
    self.qrImageView = nil;
    self.textView = nil;
    self.actionButton = nil;
    self.shareButton = nil;
    self.backgroundImageView = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
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
    
    self.qrImageView.layer.borderColor = [[UIColor blackColor] CGColor];
    self.qrImageView.layer.borderWidth = 2.0;
    
    CGFloat inset = 0.0;
    CGFloat margin = 12.0;
    
    // [self.textView setText:self.scanResult.text];
    [self.actionButton setTitle:@"Open URL"
                       forState:UIControlStateNormal];
    [self.actionButton setImage:[UIImage imageNamed:@"global/action-external"]
                      forState:UIControlStateNormal];
    [self.actionButton setImage:[UIImage imageNamed:@"global/action-external-highlighted"]
                      forState:UIControlStateHighlighted];
    
    inset = self.actionButton.frame.size.width - ([UIImage imageNamed:@"global/action-external"].size.width + margin);
    [self.actionButton setImageEdgeInsets:UIEdgeInsetsMake(0, inset, 0, 0)];
    
    [self.shareButton setTitle:@"Share this link"
                      forState:UIControlStateNormal];
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
    self.qrImageView = nil;
    self.textView = nil;
    self.actionButton = nil;
    self.shareButton = nil;
    self.backgroundImageView = nil;
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
                
            }
            else
            {
                self.resultText = self.scanResult.text;
                
                self.actionButton.hidden = YES;
                [self.shareButton setTitle:@"Share this code"
                                  forState:UIControlStateNormal];
            }
            
            self.textView.text = self.resultText;
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
