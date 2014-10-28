#import "IntroToMITController.h"
#import "UIKit+MITAdditions.h"


@implementation IntroToMITController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.navigationItem.title = @"Introduction to MIT";
    
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"intro_to_mit" ofType:@"html" inDirectory:@"tours"];
    NSAssert(templatePath,@"failed to load resource 'tours/intro_to_mit.html'");
    
    NSURL *fileURL = [NSURL fileURLWithPath:templatePath isDirectory:NO];
    
    NSError *error = nil;
    NSString *htmlString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    
    UIWebView *webview = [[UIWebView alloc] initWithFrame:self.view.bounds];
    webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webview.backgroundColor = [UIColor clearColor];
    [self.view addSubview:webview];

    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
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
