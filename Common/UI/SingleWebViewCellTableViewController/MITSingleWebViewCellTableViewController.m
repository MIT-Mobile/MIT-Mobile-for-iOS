#import "MITSingleWebViewCellTableViewController.h"
#import "UIKit+MITAdditions.h"

@interface MITSingleWebViewCellTableViewController () <UIWebViewDelegate>

@property (nonatomic, strong) NSString * htmlFormatString;
@property (nonatomic, assign) CGFloat htmlHeight;


@end

@implementation MITSingleWebViewCellTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
        self.htmlFormatString = @"<html>"
        "<head>"
        "<style type=\"text/css\" media=\"screen\">"
        "body { margin-left: auto;, margin-right:auto, padding: 0; font-family: \"Helvetica Neue\", Helvetica; font-size: 15px; }"
        "a { color: #990000; }"
        "</style>"
        "</head>"
        "<body id=\"content\">"
        "%@"
        "</body>"
        "</html>";
        
        self.htmlHeight = 44;
        self.webViewInsets = UIEdgeInsetsZero;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundView = nil;
    
    // Prevent excess cells from appearing.
    self.tableView.tableFooterView = [UIView new];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)targetTableViewHeight
{
    CGFloat tableHeight= 0.0;
    for (NSInteger section = 0; section < [self numberOfSectionsInTableView:self.tableView]; section++) {
        for (NSInteger row = 0; row < [self tableView:self.tableView numberOfRowsInSection:section]; row++) {
            tableHeight += [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
        }
    }
    
    return tableHeight;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
    }
    
    CGFloat systemHPadding = 0;
    if (tableView.style == UITableViewStyleGrouped) {
        systemHPadding = 40;   // 20 on each side when table is grouped style
    }
    
    UIWebView *existingWebView = (UIWebView *)[cell.contentView viewWithTag:42];
    if (!existingWebView) {
        existingWebView = [[UIWebView alloc] initWithFrame:CGRectMake(self.webViewInsets.left, self.webViewInsets.top, CGRectGetWidth(cell.bounds) - systemHPadding - self.webViewInsets.right, self.htmlHeight)];
        existingWebView.delegate = self;
        existingWebView.tag = 42;
        existingWebView.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber | UIDataDetectorTypeAddress;
        existingWebView.scrollView.scrollsToTop = NO;
        existingWebView.scrollView.scrollEnabled = NO;
        [cell.contentView addSubview:existingWebView];
    }
    existingWebView.frame = CGRectMake(self.webViewInsets.left, self.webViewInsets.top, CGRectGetWidth(cell.bounds) - systemHPadding - self.webViewInsets.right, self.htmlHeight);
    if (self.html) {
        [existingWebView loadHTMLString:self.html baseURL:nil];
    } else {
        [existingWebView loadHTMLString:[NSString stringWithFormat:self.htmlFormatString, self.htmlContent] baseURL:nil];
    }
    existingWebView.backgroundColor = [UIColor clearColor];
    existingWebView.opaque = NO;
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.htmlHeight + (2 * self.webViewInsets.bottom); // with some bottom padding
}


#pragma mark - WebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	// calculate webView height, if it change we need to reload table
	CGFloat newDescriptionHeight = [[webView stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"content\").scrollHeight;"] floatValue];
    CGRect frame = webView.frame;
    frame.size.height = newDescriptionHeight;
    webView.frame = frame;
    
	if(newDescriptionHeight != self.htmlHeight) {
		self.htmlHeight = newDescriptionHeight;
		[self.tableView reloadData];
        if ([self.delegate respondsToSelector:@selector(singleWebViewCellTableViewControllerDidUpdateHeight:)]) {
            [self.delegate singleWebViewCellTableViewControllerDidUpdateHeight:self];
        }
    }
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:request.URL];
        
        return NO;
    }
    return YES;
}

@end
