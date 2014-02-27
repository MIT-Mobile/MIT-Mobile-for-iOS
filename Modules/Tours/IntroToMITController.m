#import "IntroToMITController.h"
#import "UIKit+MITAdditions.h"


@implementation IntroToMITController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.navigationItem.title = @"Introduction to MIT";
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"tours/intro_to_mit.html" relativeToURL:baseURL];
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        fileURL = [NSURL URLWithString:@"tours/intro_to_mit_iOS_6.html" relativeToURL:baseURL];
    }
    
    NSError *error = nil;
    NSString *htmlString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    
    UIWebView *webview = [[UIWebView alloc] initWithFrame:self.view.bounds];
    webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webview.backgroundColor = [UIColor clearColor];
    [self.view addSubview:webview];
    [webview loadHTMLString:htmlString baseURL:baseURL];
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

@end
