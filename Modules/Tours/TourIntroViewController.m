#import "TourIntroViewController.h"
#import "CampusTour.h"
#import "SiteDetailViewController.h"
#import "TourOverviewViewController.h"
#import "MITLoadingActivityView.h"
#import "MITUIConstants.h"

@interface TourIntroViewController ()

@property (nonatomic, strong) UIWebView *webView;

- (void)loadTourInfo;
- (void)showLoadingView;
- (void)hideLoadingView;

@end

@implementation TourIntroViewController
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)selectStartingLocation {
    TourOverviewViewController *controller = [[TourOverviewViewController alloc] init];
    controller.callingViewController = self;

    [self.navigationController pushViewController:controller animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = [[ToursDataManager sharedManager] activeTour].title;
    
	[[self navigationItem] setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Intro"
                                                                                  style:UIBarButtonItemStyleBordered
                                                                                 target:nil
                                                                                 action:nil]];
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.delegate = self;
    [self.view addSubview:webView];
    self.webView = webView;

    [self loadTourInfo];
}

- (void)loadTourInfo {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tourInfoLoaded:) name:TourDetailsLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tourInfoFailedToLoad:) name:TourDetailsFailedToLoadNotification object:nil];
    
    // this just triggers a download if data is absent, we don't actually use the results
    NSArray* startLocations = [[ToursDataManager sharedManager] startLocationsForTour];
    if (![startLocations count]) {
        [self showLoadingView];
    } else {
        [self tourInfoLoaded:nil];
    }
}

- (void)tourInfoLoaded:(NSNotification *)aNotification {
    // Remember to stop observing as soon as the task is done.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TourDetailsLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TourDetailsFailedToLoadNotification object:nil];
    
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"tour_intro_template" ofType:@"html" inDirectory:@"tours"];
    NSAssert(templatePath,@"failed to load resource 'tours/tour_intro_template.html'");
    NSURL *fileURL = [NSURL fileURLWithPath:templatePath];
    
    NSError *error = nil;
    NSMutableString *html = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!html) {
        [self tourInfoFailedToLoad:nil];
        return;
    }
    
    [self hideLoadingView];

    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    [html replaceOccurrencesOfString:@"__LOCAL_BASE_URL__" withString:[baseURL absoluteString] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
	[html replaceOccurrencesOfString:@"__BODY_BEFORE_BUTTON__" withString:[[ToursDataManager sharedManager] activeTour].summary options:NSLiteralSearch range:NSMakeRange(0, [html length])];
    [html replaceOccurrencesOfString:@"__BODY_AFTER_BUTTON__" withString:[[ToursDataManager sharedManager] activeTour].moreInfo options:NSLiteralSearch range:NSMakeRange(0, [html length])];
    
    [self.webView loadHTMLString:html baseURL:baseURL];
}

- (void)tourInfoFailedToLoad:(NSNotification *)aNotification {
    // Remember to stop observing as soon as the task is done.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TourDetailsLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TourDetailsFailedToLoadNotification object:nil];

    [self hideLoadingView];
    
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"tour_intro_template" ofType:@"html" inDirectory:@"tours"];
    NSAssert(templatePath,@"failed to load resource 'tours/tour_intro_template.html'");
    NSURL *fileURL = [NSURL fileURLWithPath:templatePath];

    NSError *error = nil;
    NSMutableString *html = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    [html replaceOccurrencesOfString:@"__LOCAL_BASE_URL__" withString:[baseURL absoluteString] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
    
    [self.webView loadHTMLString:html baseURL:baseURL];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}


// copied from events
// TODO: consolidate similar loading views into Common
- (void)showLoadingView
{
	if (self.loadingIndicator == nil) {
		static NSString *loadingString = @"Loading...";
		UIFont *loadingFont = [UIFont systemFontOfSize:17.0];
		CGSize stringSize = [loadingString sizeWithFont:loadingFont];
        
        CGFloat verticalPadding = 10.0;
        CGFloat horizontalPadding = 16.0;
        CGFloat horizontalSpacing = 3.0;
        
        UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleGray;
		UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
        spinny.center = CGPointMake(spinny.center.x + horizontalPadding, spinny.center.y + verticalPadding);
		[spinny startAnimating];
        
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(spinny.frame.size.width + horizontalPadding + horizontalSpacing, verticalPadding, stringSize.width, stringSize.height + 2.0)];
        label.textColor = [UIColor grayColor];
		label.text = loadingString;
		label.font = loadingFont;
		label.backgroundColor = [UIColor clearColor];
        
		self.loadingIndicator = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, stringSize.width + spinny.frame.size.width + horizontalPadding * 2, stringSize.height + verticalPadding * 2)];
        self.loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.loadingIndicator.backgroundColor = [UIColor clearColor];
		[self.loadingIndicator addSubview:spinny];
		[self.loadingIndicator addSubview:label];
	}
    
	self.loadingIndicator.center = self.view.center;
	
	[self.view addSubview:self.loadingIndicator];
}

- (void)hideLoadingView
{
    if (self.loadingIndicator) {
        [self.loadingIndicator removeFromSuperview];
        self.loadingIndicator = nil;
    }
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	BOOL shouldStart = YES;
    
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		NSURL *url = [request URL];
		shouldStart = NO;
        if ([[url path] rangeOfString:@"select_start"].location != NSNotFound) {
            [self selectStartingLocation];
        } else if ([[url path] rangeOfString:@"retry"].location != NSNotFound) {
            [self loadTourInfo];
        } else {
			if ([[UIApplication sharedApplication] canOpenURL:url]) {
				[[UIApplication sharedApplication] openURL:url];
			}
		}

	}
	return shouldStart;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self hideLoadingView]; // also dismisses loading view
}


@end
