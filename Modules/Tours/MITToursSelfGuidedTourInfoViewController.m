#import "MITToursSelfGuidedTourInfoViewController.h"
#import "MITToursTour.h"

@interface MITToursSelfGuidedTourInfoViewController ()

@end

@implementation MITToursSelfGuidedTourInfoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Tour Details";
    
    UIWebView *webview = [[UIWebView alloc] initWithFrame:self.view.bounds];
    webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webview.backgroundColor = [UIColor clearColor];
    [self.view addSubview:webview];
    [webview loadHTMLString:self.tour.descriptionHTML baseURL:nil];
    
    [self.navigationController setToolbarHidden:YES];
}

@end
