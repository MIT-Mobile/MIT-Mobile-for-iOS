#import "CorridorDetailViewController.h"
#import "CorridorStory.h"
#import "ConnectionDetector.h"
#import "Foundation+MITAdditions.h"

@implementation CorridorDetailViewController

@synthesize story, webView;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
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
	self.webView = [[[UIWebView alloc] initWithFrame:self.view.bounds] autorelease];
    self.webView.dataDetectorTypes = UIDataDetectorTypeLink;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.scalesPageToFit = NO;
	[self.view addSubview:self.webView];
	self.webView.delegate = self;
//	self.webView.frame = self.view.bounds;

	self.navigationItem.title = @"Story";
	if (story) {
		[self displayStory];
	}
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    self.webView.delegate = nil;
    self.webView = nil;
    self.story = nil;
    [super dealloc];
}

- (void)displayStory {
//	[storyPager setEnabled:[self.newsController canSelectPreviousStory] forSegmentAtIndex:0];
//	[storyPager setEnabled:[self.newsController canSelectNextStory] forSegmentAtIndex:1];
	
	NSURL *baseURL = [[NSBundle mainBundle] resourceURL];
    NSURL *fileURL = [NSURL URLWithString:@"mit150/corridor_template.html" relativeToURL:baseURL];
    
    NSError *error = nil;
    NSMutableString *htmlString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!htmlString) {
		ELog(@"Failed to load %@", fileURL);
		ELog(@"%@", error);
        return;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM dd, y"];
    NSString *postDate = [dateFormatter stringFromDate:story.date];
	[dateFormatter release];
    
    NSString *thumbnailURL = story.imageURL;
    NSString *thumbnailWidth = [story.imageWidth stringValue];
    NSString *thumbnailHeight = [story.imageHeight stringValue];

    // if not connected, pretend there are no images
    NSString *hasImage = (thumbnailURL && [ConnectionDetector isConnected]) ? @"true" : @"false";
    
    if (!thumbnailURL) {
        thumbnailURL = @"";
    }
    if (!thumbnailWidth) {
        thumbnailWidth = @"";
    }
    if (!thumbnailHeight) {
        thumbnailHeight = @"";
    }
    
    NSArray *keys = [NSArray arrayWithObjects:
					 @"__LOCAL_BASE_URL__",
					 @"__HAS_IMAGE__", @"__AFFILIATION__", @"__TITLE__", @"__FIRST_NAME__", @"__LAST_NAME__", 
					 @"__DATE__", @"__IMG_URL__", @"__IMG_WIDTH__", @"__IMG_HEIGHT__", @"__HTML_BODY__", nil];
    
    NSArray *values = [NSArray arrayWithObjects:
					   [baseURL absoluteString],
					   hasImage, story.affiliation,
                       story.title, story.firstName, story.lastName, postDate, 
					   thumbnailURL, thumbnailWidth, thumbnailHeight, 
					   story.htmlBody, nil];
    
    [htmlString replaceOccurrencesOfStrings:keys withStrings:values options:NSLiteralSearch];
    
	[webView loadHTMLString:htmlString baseURL:baseURL];
}


@end
