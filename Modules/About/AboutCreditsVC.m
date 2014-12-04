#import "AboutCreditsVC.h"
#import "MITAdditions.h"
#import "AboutCreditsTableViewCell.h"

@interface AboutCreditsVC () <UIWebViewDelegate>
@property (nonatomic, strong) NSMutableDictionary *dict;
@end

@implementation AboutCreditsVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor mit_backgroundColor];
    self.navigationItem.title = @"Credits";
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"credits.html" relativeToURL:baseURL];
    
    NSError *error = nil;
    NSMutableString *htmlString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!htmlString) {
        return;
    }
    [self.tableView registerNib:[UINib nibWithNibName:@"AboutCreditsTableViewCell" bundle:nil] forCellReuseIdentifier:@"AboutCredits"];
    self.dict = [[NSMutableDictionary alloc] init];

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.dict[[NSNumber numberWithInt:indexPath.row]] floatValue];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AboutCreditsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AboutCredits"];
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = nil;
    if (indexPath.row == 0) {
        fileURL = [NSURL URLWithString:@"credits_current.html" relativeToURL:baseURL];
    } else {
        fileURL = [NSURL URLWithString:@"credits_past.html" relativeToURL:baseURL];
    }
    
    NSError *error = nil;
    NSMutableString *htmlString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    cell.webView.scrollView.scrollEnabled = NO;
    cell.webView.tag = indexPath.row;
    if (!self.dict[[NSNumber numberWithInt:indexPath.row]]) {
        cell.webView.delegate = self;
    } else {
        cell.webView.delegate = nil;
    }
    [cell.webView loadHTMLString:htmlString baseURL:nil];
    
    return cell;
}

#pragma mark UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
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

    self.dict[[NSNumber numberWithInt:webView.tag]] = [NSNumber numberWithFloat:size.height];

    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:webView.tag inSection:0]] withRowAnimation:(UITableViewRowAnimationNone)];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DDLogWarn(@"story view failed to load: %@", error);
}
@end

