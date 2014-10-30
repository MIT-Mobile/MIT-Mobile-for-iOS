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
#import "UIKit+MITAdditions.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"

#define START_LOCATION_ROW_HEIGHT 100.0f

@implementation StartingLocationViewController{
    NSHashTable *_connections;
}

- (void)cancelButtonTapped:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - View lifecycle
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _connections = [NSHashTable weakObjectsHashTable];
    
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    }
    
    self.navigationItem.title = @"Suggested Points";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonTapped:)];
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"suggested" ofType:@"html" inDirectory:@"tours"];
    NSAssert(templatePath,@"failed to locate resource 'tours/suggested.html'");
    
    NSURL *fileURL = [NSURL fileURLWithPath:templatePath isDirectory:NO];
    
    NSError *error = nil;
    NSMutableString *htmlString = [[NSMutableString alloc] initWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!htmlString) {
        DDLogError(@"failed to load template: %@", [error description]);
    }
    
    NSString *header = [[ToursDataManager sharedManager] activeTour].startLocationHeader;
    NSMutableString *items = [NSMutableString string];
    static NSString *itemTemplate = @"<li><a href=\"%@\">%@<strong>%@:</strong> %@</a></li>";
    BOOL floatLeft = YES;
    NSInteger count = 0;

    for (TourStartLocation *startLocation in self.startingLocations) {
        NSString *photoString = @"";

        if (startLocation.photoURL) {
            NSString *photoFile = startLocation.photoFile;
            if (![[NSFileManager defaultManager] fileExistsAtPath:photoFile]) {
                photoFile = @"tours/tour_photo_loading_animation.gif";

                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:startLocation.photoURL]];
                MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

                __weak StartingLocationViewController *weakSelf = self;
                [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSData *responseData) {
                    StartingLocationViewController *blockSelf = weakSelf;

                    [[MIT_MobileAppDelegate applicationDelegate] hideNetworkActivityIndicator];
                    [_connections removeObject:operation];

                    if (!blockSelf) {
                        return;
                    } else if (![responseData isKindOfClass:[NSData class]]) {
                        return;
                    } else {
                        for (TourStartLocation *startLocation in self.startingLocations) {
                            if ([startLocation.photoURL isEqualToString:[operation.request.URL absoluteString]]) {
                                [responseData writeToFile:startLocation.photoFile atomically:YES];
                                NSString *js = [NSString stringWithFormat:@"var img = document.getElementById(\"%@\");\n"
                                                "img.src = \"%@\";\n", startLocation.componentID, startLocation.photoFile];
                                [self.webView stringByEvaluatingJavaScriptFromString:js];
                            }
                        }
                    }
                } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
                    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
                    [_connections removeObject:operation];
                }];

                [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
                [_connections addObject:requestOperation];
                [[NSOperationQueue mainQueue] addOperation:requestOperation];
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
    
    [htmlString replaceOccurrencesOfString:@"__INTRO__" withString:header options:NSLiteralSearch range:NSMakeRange(0, [htmlString length])];
    [htmlString replaceOccurrencesOfString:@"__ITEMS__" withString:items options:NSLiteralSearch range:NSMakeRange(0, [htmlString length])];
    
    [self.view addSubview:self.webView];

    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    [self.webView loadHTMLString:htmlString baseURL:baseURL];
}

#pragma mark - UIWebViewDelegate

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
        [self.overviewController selectAnnotationForSite:location.startSite];
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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
    for (MITTouchstoneRequestOperation *connection in _connections) {
        [connection cancel];
    }

    self.webView = nil;
    self.startingLocations = nil;
    self.overviewController = nil;
}

@end

