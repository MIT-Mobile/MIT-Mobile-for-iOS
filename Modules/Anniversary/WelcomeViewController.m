#import "WelcomeViewController.h"
#import "CoreDataManager.h"

@interface WelcomeViewController (Private)

- (void)reload;
- (NSString *)cachedContent;
- (void)requestContent;
- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)result;
- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error;
- (void)displayContent:(NSString *)contentString;
	
@end


@implementation WelcomeViewController

@synthesize webView;

- (void)viewDidLoad {
	self.navigationItem.title = @"Welcome";
	
	self.webView = [[[UIWebView alloc] initWithFrame:self.view.bounds] autorelease];
    self.webView.dataDetectorTypes = UIDataDetectorTypeLink;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.scalesPageToFit = NO;
	[self.view addSubview:self.webView];
	self.webView.delegate = self;

	[self reload];
}

- (void)reload {
	NSString *contentString = [self cachedContent];
	if (!contentString) {
		[self requestContent];
	} else {
		[self displayContent:contentString];
	}
}

- (NSString *)cachedContent {
	NSManagedObject *welcomeObject = [[CoreDataManager objectsForEntity:@"WelcomeContent" matchingPredicate:[NSPredicate predicateWithValue:YES]] lastObject];
	return [welcomeObject valueForKey:@"htmlString"];
}

- (void)requestContent {
	MITMobileWebAPI *api = [MITMobileWebAPI jsonLoadedDelegate:self];
	// http://mobile-dev.mit.edu/api/anniversary.php
	BOOL dispatched = [api requestObject:nil pathExtension:@"anniversary.php"];
	if (!dispatched) {
		ELog(@"problem making welcome api request");
	}
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)result {
	if ([result isKindOfClass:[NSDictionary class]]) {
		NSDictionary *aDict = result;
		NSString *contentString = [aDict valueForKey:@"content"];
		NSManagedObject *welcomeObject = [CoreDataManager insertNewObjectForEntityForName:@"WelcomeContent"];
		[welcomeObject setValue:contentString forKey:@"htmlString"];
		// make nsmanagedobject WelcomeContent
		[CoreDataManager saveData];
		[self displayContent:contentString];
	}
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
	return YES;
}

- (void)displayContent:(NSString *)contentString {
	// including dummy data so that we have something to see when the app is reviewed before release
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"mit150/welcome.html" relativeToURL:baseURL];
	NSMutableString *htmlString = [[[NSMutableString alloc] initWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL] autorelease];

	if (!contentString) {
		NSURL *dummyURL = [NSURL URLWithString:@"mit150/welcome_placeholder.html" relativeToURL:baseURL];
		NSString *dummyString = [NSString stringWithContentsOfURL:dummyURL encoding:NSUTF8StringEncoding error:NULL];
		contentString = dummyString;
	}
	
	[htmlString replaceOccurrencesOfString:@"__CONTENT__" withString:contentString options:NSLiteralSearch range:NSMakeRange(0, [htmlString length])];
	
	[self.webView loadHTMLString:htmlString baseURL:[NSURL URLWithString:@"mit150" relativeToURL:baseURL]];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

	NSURL *url = [request URL];
	
	if (navigationType == UIWebViewNavigationTypeOther && [[url fragment] isEqualToString:@"play_video"]) {
		[self playVideo];
		return NO;
	}
	
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {

		if ([[UIApplication sharedApplication] canOpenURL:url]) {
			[[UIApplication sharedApplication] openURL:url];
		}
		
		return NO;
	}

	return YES;
}

// TODO: just use HTML5 <video> tag instead.

- (void)playVideo {
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"mit150/hockfield-150-iphone.mp4" relativeToURL:baseURL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:moviePlayer];
	
    MPMoviePlayerViewController *movieController = [[[MPMoviePlayerViewController alloc] initWithContentURL:fileURL] autorelease];
    [self presentMoviePlayerViewControllerAnimated:movieController];
    
    playingVideo = YES;
}

- (void)videoDidFinish:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[self reload]; // need to reload page or video won't play again.
    playingVideo = NO;
}

@end
