#import "MITToursTourDetailsViewController.h"
#import "MITToursTour.h"
#import "MITToursHTMLTemplateInjector.h"

@implementation MITToursTourDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Tour Details";
    
    UIWebView *webview = [[UIWebView alloc] initWithFrame:self.view.bounds];
    webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webview.backgroundColor = [UIColor clearColor];
    [self.view addSubview:webview];
    
    NSString *templatedHTML = [MITToursHTMLTemplateInjector templatedHTMLForTourDetailsHTML:self.tour.descriptionHTML viewWidth:self.view.frame.size.width];
    [webview loadHTMLString:templatedHTML baseURL:nil];
    
    [self.navigationController setToolbarHidden:YES];
}

@end
