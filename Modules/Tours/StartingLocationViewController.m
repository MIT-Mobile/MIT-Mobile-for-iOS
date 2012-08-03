#import "StartingLocationViewController.h"
#import "ToursDataManager.h"
#import "TourSiteOrRoute.h"
#import "SiteDetailViewController.h"
#import "TourOverviewViewController.h"
#import "CoreDataManager.h"
#import "SiteDetailViewController.h"
#import "TourStartLocation.h"
#import "MIT_MobileAppDelegate.h"
#import "CampusTour.h"

#define START_LOCATION_ROW_HEIGHT 100.0f

@implementation StartingLocationViewController

@synthesize startingLocations, overviewController, webView = _webView;

- (void)cancelButtonTapped:(id)sender {
    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] dismissAppModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationItem.title = @"Suggested Points";
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonTapped:)] autorelease];
    
    self.webView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)] autorelease];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"tours/suggested.html" relativeToURL:baseURL];
    
    NSError *error = nil;
    NSMutableString *htmlString = [[[NSMutableString alloc] initWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error] autorelease];
    if (!htmlString) {
        ELog(@"failed to load template: %@", [error description]);
    }
    
    NSString *header = [[ToursDataManager sharedManager] activeTour].startLocationHeader;
    NSMutableString *items = [NSMutableString string];
    static NSString *itemTemplate = @"<li><a href=\"%@\">%@<strong>%@:</strong> %@</a></li>";
    BOOL floatLeft = YES;
    NSInteger count = 0;
    
    connections = [[NSMutableArray alloc] init];
    for (TourStartLocation *startLocation in self.startingLocations) {
        
        NSString *photoString = @"";
        if (startLocation.photoURL) {
            NSString *photoFile = startLocation.photoFile;
            if (![[NSFileManager defaultManager] fileExistsAtPath:photoFile]) {
                photoFile = @"tours/tour_photo_loading_animation.gif";
                [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
                ConnectionWrapper *connection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
                [connections addObject:connection];
                [connection requestDataFromURL:[NSURL URLWithString:startLocation.photoURL]];
            }
            NSString *altText = [[startLocation.componentID componentsSeparatedByString:@"-"] lastObject];
            NSString *floatClass = [NSString stringWithFormat:@"%@%@", floatLeft ? @"floatleft" : @"floatright", count ? @" padtop" : @""];
            
            
            photoString = [NSString stringWithFormat:@"<img src=\"%@\" id=\"%@\" alt=\"%@\" width=\"160\" height=\"100\" border=\"0\" class=\"%@\">",
                           photoFile, startLocation.componentID, altText, floatClass];
            
            floatLeft = !floatLeft;
        }

        NSString *filledItem = [NSString stringWithFormat:itemTemplate,
                                startLocation.componentID,
                                photoString,
                                startLocation.title,
                                startLocation.body];
        [items appendString:filledItem];
    }
    
    [htmlString replaceOccurrencesOfString:@"__INTRO__" withString:header options:NSLiteralSearch range:NSMakeRange(0, htmlString.length)];
    [htmlString replaceOccurrencesOfString:@"__ITEMS__" withString:items options:NSLiteralSearch range:NSMakeRange(0, htmlString.length)];
    
    [self.view addSubview:self.webView];
    [self.webView loadHTMLString:htmlString baseURL:baseURL];
}

#pragma mark ConnectionWrapper

- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    for (TourStartLocation *startLocation in self.startingLocations) {
        if ([startLocation.photoURL isEqualToString:[wrapper.theURL absoluteString]]) {
            [data writeToFile:startLocation.photoFile atomically:YES];
            NSString *js = [NSString stringWithFormat:@"var img = document.getElementById(\"%@\");\n"
                            "img.src = \"%@\";\n", startLocation.componentID, startLocation.photoFile];
            [self.webView stringByEvaluatingJavaScriptFromString:js];
        }
    }
    
    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
    [connections removeObject:wrapper];
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
    [connections removeObject:wrapper];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    TourStartLocation *location = nil;
    NSString *path = [[[request URL] pathComponents] lastObject];
    for (TourStartLocation *aLocation in self.startingLocations) {
        if ([path isEqualToString:aLocation.componentID]) {
            location = aLocation;
            break;
        }
    }

    if (location) {
        [overviewController selectAnnotationForSite:location.startSite];
        [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] dismissAppModalViewControllerAnimated:YES];
    }
    
    return YES;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    self.webView = nil;
}


- (void)dealloc {
    for (ConnectionWrapper *wrapper in connections) {
        wrapper.delegate = nil;
    }
    [connections release];
    self.webView = nil;
    self.startingLocations = nil;
    self.overviewController = nil;
    [super dealloc];
}

@end

