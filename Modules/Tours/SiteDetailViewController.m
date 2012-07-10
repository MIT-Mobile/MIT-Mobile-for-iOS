#import <AVFoundation/AVFoundation.h>
#import "SiteDetailViewController.h"
#import "MITMapView.h"
#import "CoreDataManager.h"
#import "CampusTour.h"
#import "TourSiteOrRoute.h"
#import "CampusTourSideTrip.h"
#import "TourOverviewViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITMapRoute.h"
#import "ToursDataManager.h"
#import "SuperThinProgressBar.h"
#import "TourSiteMapAnnotation.h"
#import "CampusTourHomeController.h"
#import "MITMailComposeController.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "TourLink.h"

#define WEB_VIEW_TAG 646
#define END_TOUR_ALERT_TAG 878
#define CONNECTION_FAILED_TAG 451

@interface SiteDetailViewController (Private)

//- (void)setupIntroScreenForward:(BOOL)forward;
- (void)setupBottomToolBar;
- (void)setupContentAreaForward:(BOOL)forward;
- (void)setupConclusionScreen;
- (void)setupPrevNextArrows;
- (void)animateViews:(BOOL)forward;
- (void)cleanupOldViews;
- (CampusTourSideTrip *)tripForRequest:(NSURLRequest *)request;

- (void)enablePlayButton;
- (void)disablePlayButton;
- (void)hidePlayButton;
- (void)prepAudio;
- (void)playAudio;
- (void)pauseAudio;
- (void)stopAudio;

- (void)hideProgressView;

@end

@implementation SiteDetailViewController

#pragma mark Actions

@synthesize siteOrRoute = _siteOrRoute, sideTrip = _sideTrip, sites = _sites, connection, showingConclusionScreen;

- (void)feedbackButtonPressed:(id)sender {
    NSString *email = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"MITFeedbackAddress"];
    NSString *subject = [[ToursDataManager sharedManager] activeTour].feedbackSubject;
    [MITMailComposeController presentMailControllerWithRecipient:email subject:subject body:nil];
}

- (IBAction)previousButtonPressed:(id)sender {
    
    TourSiteOrRoute *previous = self.siteOrRoute.previousComponent;
    if (!showingConclusionScreen)
        self.siteOrRoute = previous;

    [self setupContentAreaForward:NO];
}

- (IBAction)nextButtonPressed:(id)sender {
    
    if (self.siteOrRoute == lastSite.nextComponent && !showingConclusionScreen) {
        [self setupConclusionScreen];
    }
    else {
        TourSiteOrRoute *next = self.siteOrRoute.nextComponent;
        self.siteOrRoute = next;

        [self setupBottomToolBar];
        [self setupContentAreaForward:YES];
    }
}

- (IBAction)overviewButtonPressed:(id)sender {
    TourOverviewViewController *vc = [[[TourOverviewViewController alloc] init] autorelease];

    NSInteger indexOfTopVC = [self.navigationController.viewControllers indexOfObject:self];
    UIViewController *callingVC = [self.navigationController.viewControllers objectAtIndex:indexOfTopVC-1];     
    if([callingVC isKindOfClass:[SiteDetailViewController class]]) {
        vc.callingViewController = callingVC;
    } else {
        vc.callingViewController = self;
    }
    vc.sideTrip = self.sideTrip;
    
    [MITAppDelegate() presentAppModalViewController:vc
                                           animated:YES];
}

#pragma mark Audio

- (void)prepAudio {
    if (!self.siteOrRoute.audioURL && !self.sideTrip.audioURL) {
        [self hidePlayButton];
        return;
    }
    
    [self enablePlayButton];
    
    TourComponent *component = (self.sideTrip == nil) ? (TourComponent *)self.siteOrRoute : (TourComponent *)self.sideTrip;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:component.audioFile]) {
        NSURL *fileURL = [NSURL fileURLWithPath:component.audioFile isDirectory:NO];
        
        NSError *error;
        [audioPlayer release];
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
        [audioPlayer prepareToPlay];
    }
}

- (void)enablePlayButton {
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tours/button_audio.png"]
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self action:@selector(playAudio)] autorelease];
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)disablePlayButton {
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)hidePlayButton {
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)hideProgressView {
    if (progressView) {
        [progressView removeFromSuperview];
        [progressView release];
        progressView = nil;
    }
}

- (void)playAudio {
    
    if (audioPlayer) {
        [audioPlayer play];

        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tours/button_audio_pause.png"]
                                                                                   style:UIBarButtonItemStyleBordered
                                                                                  target:self action:@selector(pauseAudio)] autorelease];
    }
    
    else {
        [self disablePlayButton];
        
        TourComponent *component = (self.sideTrip == nil) ? (TourComponent *)self.siteOrRoute : (TourComponent *)self.sideTrip;
        
        [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
        self.connection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
        NSURL *audioURL = [NSURL URLWithString:component.audioURL];
        [self.connection requestDataFromURL:audioURL];
        
        progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        progressView.frame = CGRectMake(200, 0, 120, 20);
        [self.view addSubview:progressView];
    }
}

- (void)pauseAudio {
    [audioPlayer pause];
    [self enablePlayButton];
}

- (void)stopAudio {
    [audioPlayer stop];

    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tours/button_audio.png"]
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self action:@selector(prepAudio)] autorelease];
    
    [audioPlayer release];
    audioPlayer = nil;
}

#pragma mark ConnectionWrapper delegate

- (void)connectionDidReceiveResponse:(ConnectionWrapper *)wrapper {
    if (progressView)
        progressView.progress = 0.1;
}

- (void)connection:(ConnectionWrapper *)wrapper madeProgress:(CGFloat)progress {
    if (progressView)
        progressView.progress = 0.1 + 0.9 * progress;
}

- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    TourComponent *component = (self.sideTrip == nil) ? (TourComponent *)self.siteOrRoute : (TourComponent *)self.sideTrip;

    if ([[wrapper.theURL absoluteString] isEqualToString:component.audioURL]) {

        [data writeToFile:component.audioFile atomically:YES];
        
        NSURL *fileURL = [NSURL fileURLWithPath:component.audioFile isDirectory:NO];
        
        NSError *error;
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
        [audioPlayer prepareToPlay];
        if (!audioPlayer) {
            ELog(@"%@", [error description]);
        }
        
        progressView.progress = 1.0;
        [UIView beginAnimations:@"fadeProgressView" context:nil];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDelay:0.3];
        [UIView setAnimationDuration:0.5];
        if (audioPlayer) {
            [UIView setAnimationDidStopSelector:@selector(playAudio)];
        }
        progressView.alpha = 0.0;
        [UIView commitAnimations];
    } else if ([[wrapper.theURL absoluteString] isEqualToString:component.photoURL]) {
        [data writeToFile:component.photoFile atomically:YES];
        NSString *js = [NSString stringWithFormat:@"var img = document.getElementById(\"directionsphoto\");\n"
                        "img.src = \"%@\";\n", component.photoFile];
        UIWebView *webView = (UIWebView *)[newSlidingView viewWithTag:WEB_VIEW_TAG];
        [webView stringByEvaluatingJavaScriptFromString:js];
    }
    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
    self.connection = nil;
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
    TourComponent *component = (self.sideTrip == nil) ? (TourComponent *)self.siteOrRoute : (TourComponent *)self.sideTrip;
    
    if ([[wrapper.theURL absoluteString] isEqualToString:component.audioURL]) {
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Connection Failed"
                                                             message:@"Audio could not be loaded"
                                                            delegate:self
                                                   cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        alertView.tag = CONNECTION_FAILED_TAG;
        [alertView show];
    }
    
    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
    self.connection = nil;
}

#pragma mark UIViewController
/*
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.appModalHolder.modalViewController) {
        return [appDelegate.appModalHolder.modalViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.appModalHolder.modalViewController) {
        [appDelegate.appModalHolder.modalViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.appModalHolder.modalViewController) {
        [appDelegate.appModalHolder.modalViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }
}
*/
/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [overviewButton setImage:[UIImage imageNamed:@"tours/toolbar_map.png"] forState:UIControlStateNormal];
    [overviewButton setTitle:nil forState:UIControlStateNormal];
    
    [backArrow setImage:[UIImage imageNamed:@"tours/toolbar_arrow_l.png"] forState:UIControlStateNormal];
    [backArrow setTitle:nil forState:UIControlStateNormal];
    [nextArrow setImage:[UIImage imageNamed:@"tours/toolbar_arrow_r.png"] forState:UIControlStateNormal];
    [nextArrow setTitle:nil forState:UIControlStateNormal];

    fakeToolbarHeightFromNIB = fakeToolbar.frame.size.height;
    [self setupBottomToolBar];    
    [self setupContentAreaForward:YES];
}

#pragma mark View setup

- (void)setupBottomToolBar {
    if (self.sideTrip == nil) {
        
        fakeToolbar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"tours/progressbar_bkgrd.png"]];
        
        CGRect frame = fakeToolbar.frame;
        frame.origin.y += frame.size.height - fakeToolbarHeightFromNIB;
        frame.size.height = fakeToolbarHeightFromNIB;
        fakeToolbar.frame = frame;
        
        progressbar.numberOfSegments = self.sites.count;
        [progressbar setNeedsDisplay];
        
        progressbar.hidden = NO;
        backArrow.hidden = NO;
        nextArrow.hidden = NO;
        
    } else {
        self.navigationItem.title = @"Side Trip";
        
        // resize the fake toolbar since there's no progress bar
        UIImage *toolbarImage = [UIImage imageNamed:@"tours/toolbar_bkgrd.png"];
        CGRect frame = fakeToolbar.frame;
        frame.origin.y += (frame.size.height - toolbarImage.size.height);
        frame.size.height = toolbarImage.size.height;
        fakeToolbar.frame = frame;
        fakeToolbar.backgroundColor = [UIColor colorWithPatternImage:toolbarImage];
        
        progressbar.hidden = YES;
        backArrow.hidden = YES;
        nextArrow.hidden = YES;
    }
}

- (void)setupPrevNextArrows {
    backArrow.enabled = self.siteOrRoute != self.firstSite;
    nextArrow.enabled = !showingConclusionScreen;
}

- (void)prepSlidingViewsForward:(BOOL)forward {
    CGFloat viewWidth = self.view.frame.size.width;
    CGFloat slideWidth = viewWidth  * (forward ? 1 : -1); 
    CGFloat xOrigin = (oldSlidingView == nil) ? 0 : slideWidth;
    CGFloat height = self.view.frame.size.height - fakeToolbar.frame.size.height;
    
    CGRect newFrame = CGRectMake(xOrigin, 0, self.view.frame.size.width, height);
    newSlidingView = [[UIScrollView alloc] initWithFrame:newFrame];
    newSlidingView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:newSlidingView];
}

- (void)setupConclusionScreen {
    showingConclusionScreen = YES;
    self.navigationItem.title = @"Thank You";
    [self hidePlayButton];
    
    [self prepSlidingViewsForward:YES];
    
    CGRect tableFrame = CGRectZero;
    tableFrame.size = newSlidingView.frame.size;
    
    UITableView *tableView = [[[UITableView alloc] initWithFrame:tableFrame style:UITableViewStyleGrouped] autorelease];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.backgroundColor = [UIColor whiteColor];
    tableView.separatorColor = [UIColor colorWithHexString:@"#BBBBBB"];

    // table footer
	NSString *buttonTitle = @"Return to MIT Home Screen";
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *buttonBackground = [UIImage imageNamed:@"global/return_button.png"];
    button.frame = CGRectMake(10, 0, buttonBackground.size.width, buttonBackground.size.height);
    [button setBackgroundImage:buttonBackground forState:UIControlStateNormal];
	button.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
	button.titleLabel.textAlignment = UITextAlignmentCenter;
    [button setTitle:buttonTitle forState:UIControlStateNormal];
    [button addTarget:self action:@selector(returnToHomeScreen:) forControlEvents:UIControlEventTouchUpInside];

    UIView *wrapperView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableFrame.size.width, buttonBackground.size.height + 10)];
    [wrapperView addSubview:button];
    tableView.tableFooterView = wrapperView;
    
    // table header
    NSSet *tourLinks = [[ToursDataManager sharedManager] activeTour].links;
    NSInteger numRows = tourLinks.count + 1;
    CGFloat currentTableHeight = tableView.rowHeight * numRows + wrapperView.frame.size.height + 10;
    CGFloat headerHeight = tableFrame.size.height - currentTableHeight - 10;
    
	UIFont *font = [UIFont systemFontOfSize:15];
	NSString *text = NSLocalizedString(@"End of tour text", nil);
	CGSize size = [text sizeWithFont:font constrainedToSize:CGSizeMake(tableFrame.size.width - 20, headerHeight - 20) lineBreakMode:UILineBreakModeWordWrap];
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 10, tableFrame.size.width - 20, size.height)] autorelease];
    label.text = text;
	label.lineBreakMode = UILineBreakModeWordWrap;
	label.numberOfLines = 0;
	[label sizeToFit];
	label.textColor = [UIColor colorWithHexString:@"#202020"];
    label.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    
    [wrapperView release];
    wrapperView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableFrame.size.width, headerHeight)] autorelease];
    [wrapperView addSubview:label];
    tableView.tableHeaderView = wrapperView;
    
    [newSlidingView addSubview:tableView];
    
    [progressbar markAsDone];
    [progressbar setNeedsDisplay];
    [self animateViews:YES];
}

- (void)setupContentAreaForward:(BOOL)forward {

    if (audioPlayer) {
        [self stopAudio];
    }
    [self prepAudio];
    
    showingConclusionScreen = NO;

    // prep views
    [self prepSlidingViewsForward:forward];
    
    UIView *newGraphic = nil;
    CGRect newFrame;
    
    TourComponent *component = (self.sideTrip == nil) ? (TourComponent *)self.siteOrRoute : (TourComponent *)self.sideTrip;

    // prep strings
    if (!siteTemplate) {
        NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
        NSURL *fileURL = [NSURL URLWithString:@"tours/site_template.html" relativeToURL:baseURL];
        
        NSError *error = nil;
        siteTemplate = [[NSString alloc] initWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    }
    NSString *nextStopPhoto = [NSString string];
    NSMutableString *body = [NSMutableString stringWithString:component.body];
    
    // populate views and strings
    if (self.sideTrip == nil) {
        if ([self.siteOrRoute.type isEqualToString:@"route"]) {
            
            self.navigationItem.title = @"Walking Directions";

            newFrame = CGRectMake(10, 10, newSlidingView.frame.size.width - 20, floor(newSlidingView.frame.size.height * 0.5));
            if (!_routeMapView) {
                _routeMapView = [[MITMapView alloc] initWithFrame:newFrame];
                _routeMapView.delegate = self;
                _routeMapView.userInteractionEnabled = NO;
                _routeMapView.showsUserLocation = YES;
                _routeMapView.stayCenteredOnUserLocation = NO;
                _routeMapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                _routeMapView.layer.borderWidth = 1.0;
                _routeMapView.layer.borderColor = [UIColor colorWithHexString:@"#C0C0C0"].CGColor;
            } else {
                _routeMapView.frame = newFrame;
            }

            [_routeMapView addRoute:[[ToursDataManager sharedManager] mapRouteForTour]];
            
            TourSiteMapAnnotation *startAnnotation = [[[TourSiteMapAnnotation alloc] init] autorelease];
            startAnnotation.site = self.siteOrRoute.previousComponent;
            
            TourSiteMapAnnotation *endAnnotation = [[[TourSiteMapAnnotation alloc] init] autorelease];
            endAnnotation.site = self.siteOrRoute.nextComponent;
            
            NSArray *pathLocations = [self.siteOrRoute pathAsArray];
            if ([pathLocations count] > 1) {
                CGPoint srcPoint = [_routeMapView convertCoordinate:startAnnotation.coordinate toPointToView:newSlidingView];
                
                CLLocation *firstPointOffSite = [pathLocations objectAtIndex:1];
                CLLocationCoordinate2D firstCoordOffSite = firstPointOffSite.coordinate;
                CGPoint destPoint = [_routeMapView convertCoordinate:firstCoordOffSite toPointToView:newSlidingView];
                
                CGFloat dy = destPoint.y - srcPoint.y;
                CGFloat dx = destPoint.x - srcPoint.x;
                CGFloat norm = sqrt(dx * dx + dy * dy);
                CGAffineTransform transform = CGAffineTransformMake(dx/norm, dy/norm, -dy/norm, dx/norm, 0, 0);
                startAnnotation.transform = transform;
                startAnnotation.hasTransform = YES;
                
                CLLocation *lastPointOffDest = [pathLocations objectAtIndex:[pathLocations count] - 2];
                CLLocationCoordinate2D lastCoordOffDest = lastPointOffDest.coordinate;
                srcPoint = [_routeMapView convertCoordinate:lastCoordOffDest toPointToView:newSlidingView];
                destPoint = [_routeMapView convertCoordinate:endAnnotation.coordinate toPointToView:newSlidingView];
                
                dy = destPoint.y - srcPoint.y;
                dx = destPoint.x - srcPoint.x;
                norm = sqrt(dx * dx + dy * dy);
                transform = CGAffineTransformMake(dx/norm, dy/norm, -dy/norm, dx/norm, 0, 0);
                endAnnotation.transform = transform;
                endAnnotation.hasTransform = YES;
                
                directionsRoute = [[MITGenericMapRoute alloc] init];
                directionsRoute.lineWidth = 6;
                UIColor *color = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
                directionsRoute.fillColor = color;
                directionsRoute.strokeColor = color;
                directionsRoute.pathLocations = pathLocations;
                [_routeMapView addRoute:directionsRoute];
            }

            [_routeMapView addAnnotation:startAnnotation];
            [_routeMapView addAnnotation:endAnnotation];
            
            CLLocationCoordinate2D center = CLLocationCoordinate2DMake((startAnnotation.coordinate.latitude + endAnnotation.coordinate.latitude) / 2,
                                                                       (startAnnotation.coordinate.longitude + endAnnotation.coordinate.longitude) / 2);
            _routeMapView.zoomLevel = [self.siteOrRoute.zoom floatValue];
            _routeMapView.centerCoordinate = center;
            
            newGraphic = _routeMapView;
            
            if (component.photoURL) {
                NSString *photoFile = component.photoFile;
                NSInteger imageWidth = 160;
                NSInteger imageHeight = 100;
                if (![[NSFileManager defaultManager] fileExistsAtPath:photoFile]) {
                    photoFile = [NSString stringWithString:@"tours/tour_photo_loading_animation.gif"];
                    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
                    self.connection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
                    [self.connection requestDataFromURL:[NSURL URLWithString:component.photoURL]];
                }
                
                TourSiteOrRoute *nextComponent = self.siteOrRoute.nextComponent;
                
                nextStopPhoto = [NSString stringWithFormat:@"<div class=\"photo\"><img id=\"directionsphoto\" src=\"%@\" width=\"%d\" height=\"%d\">%@</div>",
                                 photoFile, imageWidth, imageHeight,
                                 nextComponent.title];
            }
            
        } else {
            self.navigationItem.title = @"Detail";
        }
        
        if (self.siteOrRoute != self.firstSite) {
            UIBarButtonItem *endTourButton = [[[UIBarButtonItem alloc] initWithTitle:@"End Tour"
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(endTour:)] autorelease];
            self.navigationItem.leftBarButtonItem = endTourButton;
        } else {
            self.navigationItem.leftBarButtonItem = nil; // default back button
        }
        
        static NSString *sideTripTemplate = @"<p class=\"sidetrip\"><a href=\"%@\">Side Trip: %@</a></p>";
        for (CampusTourSideTrip *aTrip in self.siteOrRoute.sideTrips) {
            NSString *tripHTML = [NSString stringWithFormat:sideTripTemplate, aTrip.componentID, aTrip.title];
            NSString *stringToReplace = [NSString stringWithFormat:@"__SIDE_TRIP_%@__", aTrip.componentID];
            [body replaceOccurrencesOfString:stringToReplace withString:tripHTML options:NSLiteralSearch range:NSMakeRange(0, [body length])];
        }
    }
    
    if (!newGraphic) { // site or side trip detail
        
        NSInteger progress = [self.sites indexOfObject:self.siteOrRoute];
        if (progress != NSNotFound) {
            progressbar.currentPosition = progress;
            [progressbar setNeedsDisplay];
        }
        
        newFrame = CGRectMake(0, 0, newSlidingView.frame.size.width, floor(newSlidingView.frame.size.height * 0.5));
        MITThumbnailView *thumb = [[[MITThumbnailView alloc] initWithFrame:newFrame] autorelease];
        NSData *imageData = component.photo;
        NSString *imageURL = component.photoURL;
        
        if (imageData != nil) { 
            thumb.imageData = imageData;
        } else {
            thumb.imageURL = imageURL;
        }
        
        thumb.delegate = self;
        [thumb loadImage];
        newGraphic = thumb;
    }
    
    [newSlidingView addSubview:newGraphic];
    
    newFrame = CGRectMake(0, newFrame.origin.y + newFrame.size.height, self.view.frame.size.width,
                          self.view.frame.size.height - newFrame.size.height - fakeToolbar.frame.size.height);
    
    UIWebView *webView = [[[UIWebView alloc] initWithFrame:newFrame] autorelease];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.delegate = self;
    webView.tag = WEB_VIEW_TAG;
	
	// prevent webView from scrolling separately from the parent scrollview
	for (id subview in webView.subviews) {
		if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
			((UIScrollView *)subview).bounces = NO;
		}
	}

    NSMutableString *html = [NSMutableString stringWithString:siteTemplate];
    NSString *maxWidth = [NSString stringWithFormat:@"%.0f", webView.frame.size.width];
    [html replaceOccurrencesOfString:@"__WIDTH__" withString:maxWidth options:NSLiteralSearch range:NSMakeRange(0, html.length)];
    [html replaceOccurrencesOfString:@"__TITLE__" withString:component.title options:NSLiteralSearch range:NSMakeRange(0, html.length)];
    [html replaceOccurrencesOfString:@"__PHOTO__" withString:nextStopPhoto options:NSLiteralSearch range:NSMakeRange(0, html.length)];
    [html replaceOccurrencesOfString:@"__BODY__" withString:body options:NSLiteralSearch range:NSMakeRange(0, html.length)];
    
	NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];

    [webView loadHTMLString:html baseURL:baseURL];
    
    [newSlidingView addSubview:webView];
    
    [self animateViews:forward];
}

- (void)animateViews:(BOOL)forward {
    nextArrow.enabled = NO;
    backArrow.enabled = NO;

    if (oldSlidingView) {
        
        CGFloat viewWidth = self.view.frame.size.width;
        CGFloat transitionWidth = viewWidth  * (forward ? 1 : -1); 
        
        [UIView beginAnimations:@"tourAnimation" context:nil];
        [UIView setAnimationDuration:0.4];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(cleanupOldViews)];
        oldSlidingView.center = CGPointMake(oldSlidingView.center.x - transitionWidth, oldSlidingView.center.y);
        newSlidingView.center = CGPointMake(newSlidingView.center.x - transitionWidth, newSlidingView.center.y);
        [UIView commitAnimations];
        
    }
    else {
        oldSlidingView = newSlidingView;
        [self setupPrevNextArrows];
    }

}

- (void)cleanupOldViews {
    if (!self.sideTrip && [self.siteOrRoute.type isEqualToString:@"site"] && directionsRoute) {
        [_routeMapView removeRoute:directionsRoute];
        [directionsRoute release];
        directionsRoute = nil;
        [_routeMapView removeAllAnnotations:NO];
    }
    
    [oldSlidingView removeFromSuperview];
    [oldSlidingView release];
    
    oldSlidingView = newSlidingView;
    
    [self setupPrevNextArrows];
}

#pragma mark Navigation

- (void)endTour:(id)sender {
	UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"End Tour?"
														 message:@"Are you sure you want to end the tour?"
														delegate:self
											   cancelButtonTitle:@"Cancel"
											   otherButtonTitles:@"OK", nil] autorelease];
	alertView.tag = END_TOUR_ALERT_TAG;
	[alertView show];
}

- (void)returnToHomeScreen:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)jumpToSite:(NSInteger)siteIndex {
    TourSiteOrRoute *site = [self.sites objectAtIndex:siteIndex];
    
    // TODO: clean up so we're not doing the same thing here and in TourOverviewViewController
    NSInteger currentSiteIndex;
    if ([self.siteOrRoute.type isEqualToString:@"site"]) {
        currentSiteIndex = [self.sites indexOfObject:self.siteOrRoute];
    } else {
        currentSiteIndex = [self.sites indexOfObject:self.siteOrRoute.nextComponent];
    }
    
    self.siteOrRoute = site;
    
    BOOL forward = currentSiteIndex < siteIndex;
    
    [self setupBottomToolBar];
    [self setupContentAreaForward:forward];
}

- (TourSiteOrRoute *)firstSite {
    return firstSite;
}

- (void)setFirstSite:(TourSiteOrRoute *)aSite {
    if (firstSite != aSite) {
        [firstSite release];
        firstSite = [aSite retain];
        [lastSite release];
        
        if(firstSite != nil) {
            self.sites = [[ToursDataManager sharedManager] allSitesStartingFrom:firstSite];
            lastSite = [firstSite.previousComponent.previousComponent retain];
        } else {
            self.sites = nil;
            lastSite = nil;
        }
    }
}

#pragma mark Memory

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    if (audioPlayer) { // don't use stopAudio as it accesses the nav bar
        [audioPlayer stop];
        [audioPlayer release];
        audioPlayer = nil;
    }
    [self hideProgressView]; // also releases progress view
    self.connection.delegate = nil;
    self.connection = nil;
}

- (void)viewDidUnload {
    [super viewDidUnload];

    //[_routeMapView release];
    //_routeMapView = nil;
    
    [oldSlidingView release];
    oldSlidingView = nil;
}


- (void)dealloc {
    [_routeMapView removeTileOverlay];
    _routeMapView.delegate = nil;
    [_routeMapView release];
    
    if (audioPlayer) {
        [audioPlayer stop];
        [audioPlayer release];
    }
    [self hideProgressView]; // also releases progress view
    self.connection.delegate = nil;
    self.connection = nil;
    self.siteOrRoute = nil;
    self.sideTrip = nil;
    self.sites = nil;
    self.firstSite = nil;
    [siteTemplate release];
    [lastSite release];
    [oldSlidingView release];
    [super dealloc];
}

#pragma mark -
#pragma mark MITThumbnailDelegate

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data {
    TourComponent *component = (self.sideTrip == nil) ? (TourComponent *)self.siteOrRoute : (TourComponent *)self.sideTrip;
    if ([thumbnail.imageURL isEqualToString:component.photoURL]) {
        component.photo = data;
    }
}

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[request.URL absoluteString] rangeOfString:@"http"].location == 0) {
        if ([[UIApplication sharedApplication] canOpenURL:request.URL]) {
            [[UIApplication sharedApplication] openURL:request.URL];
        }
        return NO;
    }

    if (self.sideTrip == nil) {
        CampusTourSideTrip *trip = [self tripForRequest:request];
        if (trip) {
            SiteDetailViewController *sideTripVC = [[[SiteDetailViewController alloc] init] autorelease];
            sideTripVC.sideTrip = trip;
            sideTripVC.sites = self.sites;
            sideTripVC.siteOrRoute = self.siteOrRoute;
            [self.navigationController pushViewController:sideTripVC animated:YES];
            return NO;
        }
    }
    return YES;
}

- (TourComponent *)tripForRequest:(NSURLRequest *)request {
    NSArray *pathComponents = [[request.URL path] pathComponents];
    if (pathComponents.count) {
        NSString *maybeTripID = [pathComponents lastObject];
        for (CampusTourSideTrip *aTrip in self.siteOrRoute.sideTrips) {
            if ([maybeTripID isEqualToString:aTrip.componentID]) {
                return aTrip;
            }
        }
    }
    return nil;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    CGSize size = [webView sizeThatFits:CGSizeZero];
    CGRect frame = webView.frame;
    CGFloat addedHeight = size.height - frame.size.height;
    frame.size.height = size.height;
    webView.frame = frame;

    if (addedHeight > 0) {
        // increase scrollview height by how much the webview height grows
        CGSize contentSize = newSlidingView.contentSize;
        contentSize.height = newSlidingView.frame.size.height + addedHeight;
        newSlidingView.contentSize = contentSize;
    }
}

#pragma mark MITMapViewDelegate

- (MITMapAnnotationView *)mapView:(MITMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    TourSiteMapAnnotation *tourAnnotation = (TourSiteMapAnnotation *)annotation;
    MITMapAnnotationView *annotationView = [[[MITMapAnnotationView alloc] initWithAnnotation:tourAnnotation reuseIdentifier:@"toursite"] autorelease];
    
    TourSiteOrRoute *site = tourAnnotation.site;
    TourSiteOrRoute *upcomingSite = self.siteOrRoute.nextComponent;
    UIImage *marker;
    if (upcomingSite == site) {
        marker = [UIImage imageNamed:@"tours/map_ending_arrow.png"];
    } else {
        marker = [UIImage imageNamed:@"tours/map_starting_arrow.png"];
    }
    annotationView.image = marker;
    annotationView.showsCustomCallout = NO;
    
    if (tourAnnotation.hasTransform) {
        annotationView.transform = tourAnnotation.transform;
    }
    
    return annotationView;
}

#pragma mark tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    NSSet *tourLinks = [[ToursDataManager sharedManager] activeTour].links;
    return tourLinks.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.backgroundColor = [UIColor colorWithHexString:@"#E0E0E0"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    if (indexPath.row == 0) {
        cell.textLabel.text = @"Send feedback";
        cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
        
    } else {
        NSSet *tourLinks = [[ToursDataManager sharedManager] activeTour].links;
        NSArray *sortedLinks = [tourLinks sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES]]];
        TourLink *link = [sortedLinks objectAtIndex:indexPath.row - 1];
        cell.textLabel.text = link.title;
        if ([link.url rangeOfString:@"http"].location == 0) {
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
        } else {
            cell.accessoryView = [UIImageView accessoryViewForInternalURL:link.url];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        [self feedbackButtonPressed:nil];
        
    } else {
        NSSet *tourLinks = [[ToursDataManager sharedManager] activeTour].links;
        NSArray *sortedLinks = [tourLinks sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES]]];
        TourLink *link = [sortedLinks objectAtIndex:indexPath.row - 1];
        NSURL *url = [NSURL URLWithString:link.url];
        
        if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == CONNECTION_FAILED_TAG) {
        [UIView beginAnimations:@"fadeProgressView" context:nil];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDelay:0.3];
        [UIView setAnimationDuration:0.5];
        if (audioPlayer) {
            [UIView setAnimationDidStopSelector:@selector(hideProgressView)];
        }
        progressView.alpha = 0.0;
        [UIView commitAnimations];
    }
    
	else if (alertView.tag == END_TOUR_ALERT_TAG && buttonIndex != [alertView cancelButtonIndex]) {
		CampusTourHomeController *theController = nil;
		for (UIViewController *aController in self.navigationController.viewControllers) {
			if ([aController isKindOfClass:[CampusTourHomeController class]]) {
				theController = (CampusTourHomeController *)aController;
                break;
			}
		}
		if (theController) {
			[self.navigationController popToViewController:theController animated:YES];
		}
	}
}

@end
