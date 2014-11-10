#import <QuartzCore/QuartzCore.h>

#import "QRReaderDetailViewController.h"
#import "QRReaderResult.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "MITLoadingActivityView.h"
#import "NSDateFormatter+RelativeString.h"
#import "UIKit+MITAdditions.h"

@interface QRReaderDetailViewController () <ShareItemDelegate,UITableViewDataSource,UITableViewDelegate>
@property (strong) NSString *resultText;
@property (strong) NSOperation *urlMappingOperation;
@property (weak) MITLoadingActivityView *loadingView;

#pragma mark - Public Properties
@property (strong) QRReaderResult *scanResult;

#pragma mark - IBOutlets
@property (weak) IBOutlet UIScrollView *scrollView;
@property (weak) IBOutlet UIImageView *qrImageView;
@property (weak) IBOutlet UIImageView *backgroundImageView;
@property (weak) IBOutlet UILabel *textTitleLabel;
@property (weak) IBOutlet UILabel *textView;
@property (weak) IBOutlet UILabel *dateLabel;
@property (weak) IBOutlet UITableView *scanActionTable;
@property (strong) NSMutableArray *scanActions;
@property (strong) NSDictionary *scanShareDetails;
@property (strong) NSString *scanType;
#pragma mark -
@end

@implementation QRReaderDetailViewController
+ (QRReaderDetailViewController*)detailViewControllerForResult:(QRReaderResult*)result {
    QRReaderDetailViewController *reader = [[self alloc] initWithNibName:@"QRReaderDetailViewController"
                                                                  bundle:nil];
    reader.scanResult = result;
    return reader;
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


#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    if (self.scanResult.scanImage) {
        self.qrImageView.image = self.scanResult.scanImage;
    } else {
        self.qrImageView.image = [UIImage imageNamed:MITImageScannerMissingImage];
    }

    self.scanActions = [NSMutableArray array];
    
    {
        CGRect loadingViewBounds = self.view.bounds;
        loadingViewBounds.origin.y += CGRectGetHeight(self.qrImageView.frame);
        loadingViewBounds.size.height -= CGRectGetHeight(self.qrImageView.frame);
        
        MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:loadingViewBounds];
        loadingView.hidden = NO;
        [self.view addSubview:loadingView];
        self.loadingView = loadingView;
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
    
    // Check for any available code => URL mappings from
    // the mobile server
    {
        NSURLRequest *request = [NSURLRequest requestForModule:@"qr" command:nil parameters:@{@"q" : self.scanResult.text}];
        MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

        __weak QRReaderDetailViewController *weakSelf = self;
        [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSDictionary *codeInfo) {
            [weakSelf handleScanInfoResponse:codeInfo error:nil];
        } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
            [weakSelf handleScanInfoResponse:nil error:error];
        }];

        self.urlMappingOperation = requestOperation;
        
        [[NSOperationQueue mainQueue] addOperation:requestOperation];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.urlMappingOperation cancel];
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

- (void)handleScanInfoResponse:(NSDictionary*)codeInfo error:(NSError*)error
{
    BOOL success = (error == nil) && [codeInfo[@"success"] boolValue];
    
    NSArray *actions = codeInfo[@"actions"];
    BOOL validResponse = actions && [actions isKindOfClass:[NSArray class]];
    
    if (success && validResponse) {
        [self.scanActions removeAllObjects];
        for (NSDictionary *action in actions) {
            if ([action isKindOfClass:[NSDictionary class]] == NO) {
                validResponse = NO;
                break;
            } else {
                [self.scanActions addObject:action];
            }
        }
        
        if (validResponse) {
            self.scanShareDetails = codeInfo[@"share"];
            self.textTitleLabel.text = codeInfo[@"displayType"];
            self.textView.text = codeInfo[@"displayName"];
            self.scanType = codeInfo[@"type"];
        }
    }
    
    if (validResponse == NO)
    {
        DDLogVerbose(@"Did not recieve a valid action response from the server for code '%@'", self.scanResult.text);
        
        [self.scanActions removeAllObjects];
        NSURL *url = [NSURL URLWithString:self.scanResult.text];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            self.scanShareDetails = @{@"title" : @"Share URL",
                                      @"data" : self.scanResult.text};
            [self.scanActions addObject:@{@"title" : @"Open URL",
                                          @"url" : self.scanResult.text}];
            self.scanType = @"url";
            self.textTitleLabel.text = @"URL";
            self.textView.text = self.scanResult.text;
        } else {
            self.scanShareDetails = @{@"title" : @"Share data",
                                      @"data" : self.scanResult.text};
            self.scanType = @"other";
            self.textTitleLabel.text = @"Other";
            self.textView.text = self.scanResult.text;
        }
    }

    CGSize boundingSize = CGSizeMake(CGRectGetWidth(self.textView.frame), CGFLOAT_MAX);
    CGSize requiredSize = [self.textView.text sizeWithFont:self.textView.font
                                                constrainedToSize:boundingSize
                                                lineBreakMode:NSLineBreakByWordWrapping];
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

#pragma mark - IBAction methods
- (IBAction)pressedShareButton:(id)sender {
    if (self.scanShareDetails)
    {
        self.shareDelegate = self;
        [self share:self];
    }
}

- (IBAction)pressedActionButton:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.resultText]];
}

#pragma mark -
#pragma mark ShareItemDelegate (MIT)
- (NSString *)actionSheetTitle {
	return self.scanShareDetails[@"data"];
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
    
    if (indexPath.row < [self.scanActions count]) {
        NSDictionary *cellDetails = self.scanActions[indexPath.row];
        NSURL *url = [NSURL URLWithString:cellDetails[@"url"]];
        
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    } else if (self.scanShareDetails) {
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
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:actionCellIdentifier];
    }
    
    
    if (indexPath.row < [self.scanActions count]) {
        NSDictionary *cellDetails = [self.scanActions objectAtIndex:indexPath.row];
        
        cell.textLabel.text = cellDetails[@"title"];
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageActionExternal]
                                               highlightedImage:[UIImage imageNamed:MITImageActionExternalHighlight]];
    } else {
        cell.textLabel.text = self.scanShareDetails[@"title"];
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageNameShare]];
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
