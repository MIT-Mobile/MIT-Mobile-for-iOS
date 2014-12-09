#import "AboutCreditsVC.h"
#import "MITAdditions.h"
#import "AboutCreditsTableViewCell.h"
#import "AboutCreditsViewOlderTableViewCell.h"

NSString* const AboutCreditsViewOlderTableViewNibName = @"AboutCreditsViewOlderTableViewCell";
NSString* const AboutCreditsViewOlderTableViewIdentifier = @"AboutCreditsViewOlder";
NSString* const AboutCreditsTableViewCellNibName = @"AboutCreditsTableViewCell";
NSString* const AboutCreditsTableViewCellIdentifier = @"AboutCredits";

@interface AboutCreditsVC () <UIWebViewDelegate>
@property (nonatomic, strong) NSMutableDictionary *webViewHeightsDictionary;
@property (nonatomic) BOOL showOlderCredits;
@end

@interface AboutCreditsVC ()
@property(nonatomic,weak) UIWebView *webView;
@end

@implementation AboutCreditsVC

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = @"Credits";
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.tableView registerNib:[UINib nibWithNibName:AboutCreditsTableViewCellNibName bundle:nil] forCellReuseIdentifier:AboutCreditsTableViewCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:AboutCreditsViewOlderTableViewNibName bundle:nil] forCellReuseIdentifier:AboutCreditsViewOlderTableViewIdentifier];
}

- (NSMutableDictionary *)webViewHeightsDictionary
{
    if(!_webViewHeightsDictionary) {
        NSMutableDictionary *webViewHeightsDictionary = [[NSMutableDictionary alloc] init];
        _webViewHeightsDictionary = webViewHeightsDictionary;
    }
    return _webViewHeightsDictionary;
}

#pragma mark - UITableView Methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.webViewHeightsDictionary[[NSNumber numberWithInt:indexPath.row]]) {
        return [self.webViewHeightsDictionary[[NSNumber numberWithInt:indexPath.row]] floatValue];
    }
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.showOlderCredits = YES;
    [self.tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0 || self.showOlderCredits) {
        NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
        NSURL *fileURL = nil;
        if (indexPath.row == 0) {
            fileURL = [NSURL URLWithString:@"credits_current.html" relativeToURL:baseURL];
        } else {
            fileURL = [NSURL URLWithString:@"credits_past.html" relativeToURL:baseURL];
        }
        
        NSError *error = nil;
        NSMutableString *htmlString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];

        AboutCreditsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AboutCreditsTableViewCellIdentifier];
        cell.webView.scrollView.scrollEnabled = NO;
        cell.webView.tag = indexPath.row;
        if (!self.webViewHeightsDictionary[[NSNumber numberWithInt:indexPath.row]]) {
            cell.webView.delegate = self;
        } else {
            cell.webView.delegate = nil;
        }
        [cell.webView loadHTMLString:htmlString baseURL:nil];
        
        return cell;
        
    } else {
        AboutCreditsViewOlderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AboutCreditsViewOlderTableViewIdentifier];
        return cell;
    }
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView
{
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // Set the height to '1' here so that when we update the
    // view constraints in updateViewConstraints, the web view
    // returns the correct minimum size it needs to fit the content
    // when sizeThatFitsSize: is called. '1' may or may not be a magic
    // number here; using either '0' or leaving the frame at its
    // default sizing results in incorrect behavior
    CGRect frame = webView.frame;
    frame.size.height = 1;
    webView.frame = frame;
    CGSize size = [webView sizeThatFits:CGSizeZero];

    self.webViewHeightsDictionary[[NSNumber numberWithInt:webView.tag]] = [NSNumber numberWithFloat:size.height];

    [self.tableView reloadData];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DDLogWarn(@"credits view at index %d failed to load: %@",webView.tag, error);
}
@end

