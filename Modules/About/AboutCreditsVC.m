#import "AboutCreditsVC.h"
#import "MITAdditions.h"

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
    
    UIWebView *webview = [[UIWebView alloc] initWithFrame:self.view.bounds];
    webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webview.backgroundColor = [UIColor clearColor];
    [self.view addSubview:webview];
    [webview loadHTMLString:htmlString baseURL:nil];
}

@end

