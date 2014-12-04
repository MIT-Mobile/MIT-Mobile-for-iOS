#import "MITToursTourDetailsViewController.h"
#import "MITToursTour.h"
#import "MITToursHTMLTemplateInjector.h"

@interface MITToursTourDetailsViewController () <UIWebViewDelegate>

@end

@implementation MITToursTourDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Tour Details";
    
    [self.navigationController setToolbarHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    UIWebView *webview = [[UIWebView alloc] initWithFrame:self.view.bounds];
    webview.delegate = self;
    webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webview.backgroundColor = [UIColor clearColor];
    [self.view addSubview:webview];
    
    NSString *templatedHTML = [MITToursHTMLTemplateInjector templatedHTMLForTourDetailsHTML:self.tour.descriptionHTML viewWidth:self.view.frame.size.width];
    [webview loadHTMLString:templatedHTML baseURL:nil];
}

- (BOOL)webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType
{
    if (inType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    return YES;
}

@end
