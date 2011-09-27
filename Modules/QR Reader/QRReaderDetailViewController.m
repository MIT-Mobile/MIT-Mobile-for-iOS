#import <QuartzCore/QuartzCore.h>

#import "QRReaderDetailViewController.h"
#import "QRReaderResult.h"

@interface QRReaderDetailViewController ()
@property (nonatomic,retain) QRReaderResult *scanResult;
@property (nonatomic,retain) UIImageView *qrImage;
@property (nonatomic,retain) UIImageView *backgroundImageView;
@property (nonatomic,retain) UITextView *textView;
@property (nonatomic,retain) UIButton *actionButton;
@property (nonatomic,retain) UIButton *shareButton;
@end

@implementation QRReaderDetailViewController
@synthesize scanResult = _scanResult;
@synthesize qrImage = _qrImage;
@synthesize textView = _textView;
@synthesize actionButton = _actionButton;
@synthesize shareButton = _shareButton;
@synthesize backgroundImageView = _backgroundImageView;

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
        self.title = @"QR Details";
    }
    return self;
}

- (void)dealloc
{
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
        self.qrImage.image = self.scanResult.image;
    } else {
        self.qrImage.image = [UIImage imageNamed:@"qrreader/qr-missing-image"];
    }
    
    self.qrImage.layer.borderColor = [[UIColor blackColor] CGColor];
    self.qrImage.layer.borderWidth = 2.0;
    
    CGFloat inset = 0.0;
    CGFloat margin = 12.0;
    
    [self.textView setText:self.scanResult.text];
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
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    self.qrImage = nil;
    self.textView = nil;
    self.actionButton = nil;
    self.shareButton = nil;
    self.backgroundImageView = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setToolbarHidden:NO
                                       animated:animated];
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
    NSString *altURL = self.scanResult.text;
    
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
	return [NSString stringWithString:@"Share This Link"];
}

- (NSString *)emailSubject {
	return [NSString stringWithFormat:@"%@", self.scanResult.text];
}

- (NSString *)emailBody {
	return [NSString stringWithFormat:@"I thought you might be interested in this link...\n\n%@", self.scanResult.text];
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
            self.scanResult.text,
            @"MIT QR Code"];
}

- (NSString *)twitterUrl {
    return self.scanResult.text;
}

- (NSString *)twitterTitle {
	return self.scanResult.text;
}
@end
