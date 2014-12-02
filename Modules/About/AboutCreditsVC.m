#import "AboutCreditsVC.h"
#import "MITAdditions.h"

@interface AboutCreditsVC ()
@property(nonatomic,weak) UIWebView *webView;
@end

@implementation AboutCreditsVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor mit_backgroundColor];
    self.navigationItem.title = @"Credits";
    
    UIWebView *webview = [[UIWebView alloc] init];
    webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webview.backgroundColor = [UIColor clearColor];
    [self.view addSubview:webview];
    self.webView = webview;


    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"credits.html" relativeToURL:baseURL];

    NSError *error = nil;
    NSMutableString *htmlString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    [self.webView loadHTMLString:htmlString baseURL:baseURL];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.webView.frame = self.view.bounds;
}

@end

