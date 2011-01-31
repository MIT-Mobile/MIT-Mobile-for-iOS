#import "StoryDetailViewController.h"
#import "MIT_MobileAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "NewsStory.h"
#import "CoreDataManager.h"
#import "Foundation+MITAdditions.h"
#import "StoryListViewController.h"
#import "StoryGalleryViewController.h"
#import "ConnectionDetector.h"
#import "URLShortener.h"
#import "MITMobileServerConfiguration.h"

@implementation StoryDetailViewController

@synthesize newsController, story, storyView;

- (void)loadView {
    [super loadView]; // surprisingly necessary empty call to super due to the way memory warnings work
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.shareDelegate = self;
	
	storyPager = [[UISegmentedControl alloc] initWithItems:
											[NSArray arrayWithObjects:
											 [UIImage imageNamed:MITImageNameUpArrow], 
											 [UIImage imageNamed:MITImageNameDownArrow], 
											 nil]];
	[storyPager setMomentary:YES];
	[storyPager setEnabled:NO forSegmentAtIndex:0];
	[storyPager setEnabled:NO forSegmentAtIndex:1];
	storyPager.segmentedControlStyle = UISegmentedControlStyleBar;
	storyPager.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	storyPager.frame = CGRectMake(0, 0, 80.0, storyPager.frame.size.height);
	[storyPager addTarget:self action:@selector(didPressNavButton:) forControlEvents:UIControlEventValueChanged];
	
	UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: storyPager];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	[segmentBarItem release];
	
    self.view.opaque = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	storyView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    storyView.dataDetectorTypes = UIDataDetectorTypeLink;
    storyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    storyView.scalesPageToFit = NO;
	[self.view addSubview: storyView];
	storyView.delegate = self;
	
	if (self.story) {
		[self displayStory:self.story];
	}
}

- (void)displayStory:(NewsStory *)aStory {
	[storyPager setEnabled:[self.newsController canSelectPreviousStory] forSegmentAtIndex:0];
	[storyPager setEnabled:[self.newsController canSelectNextStory] forSegmentAtIndex:1];

	NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"news/news_story_template.html" relativeToURL:baseURL];
    
    NSError *error = nil;
    NSMutableString *htmlString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!htmlString) {
        return;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM dd, y"];
    NSString *postDate = [dateFormatter stringFromDate:story.postDate];
	[dateFormatter release];
    
    NSString *thumbnailURL = story.inlineImage.smallImage.url;
    NSString *thumbnailWidth = [story.inlineImage.smallImage.width stringValue];
    NSString *thumbnailHeight = [story.inlineImage.smallImage.height stringValue];
    if (!thumbnailURL) {
        thumbnailURL = @"";
    }
    if (!thumbnailWidth) {
        thumbnailWidth = @"";
    }
    if (!thumbnailHeight) {
        thumbnailHeight = @"";
    }
    
    NSInteger galleryCount = [story.galleryImages count];
    if (story.inlineImage) {
        galleryCount++;
    }
    
    // if not connected, pretend there are no images
    NSString *galleryCountString = ([ConnectionDetector isConnected]) ? [[NSNumber numberWithInteger:galleryCount] stringValue] : @"0";
    
    NSArray *keys = [NSArray arrayWithObjects:
                     @"__TITLE__", @"__AUTHOR__", @"__DATE__", @"__BOOKMARKED__",
                     @"__THUMBNAIL_URL__", @"__THUMBNAIL_WIDTH__", @"__THUMBNAIL_HEIGHT__", 
					 @"__GALLERY_COUNT__", @"__DEK__", @"__BODY__", nil];
    
	NSString *isBookmarked = ([self.story.bookmarked boolValue]) ? @"on" : @"";
	
    NSArray *values = [NSArray arrayWithObjects:
                       story.title, story.author, postDate, isBookmarked, 
					   thumbnailURL, thumbnailWidth, thumbnailHeight, 
					   galleryCountString, story.summary, story.body, nil];
    
    [htmlString replaceOccurrencesOfStrings:keys withStrings:values options:NSLiteralSearch];
    
    // mark story as read
    self.story.read = [NSNumber numberWithBool:YES];
	[CoreDataManager saveDataWithTemporaryMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
	[storyView loadHTMLString:htmlString baseURL:baseURL];
}

- (void)didPressNavButton:(id)sender {
    if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *theControl = (UISegmentedControl *)sender;
        NSInteger i = theControl.selectedSegmentIndex;
		NewsStory *newStory = nil;
        if (i == 0) { // previous
			newStory = [self.newsController selectPreviousStory];
        } else { // next
			newStory = [self.newsController selectNextStory];
        }
		if (newStory) {
			self.story = newStory;
			[self displayStory:self.story]; // updates enabled state of storyPager as a side effect
		}
    }
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	BOOL result = YES;
    
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		NSURL *url = [request URL];
        NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]];

		if ([[url path] rangeOfString:[baseURL path] options:NSAnchoredSearch].location == NSNotFound) {
            [[UIApplication sharedApplication] openURL:url];
            result = NO;
        } else {
			if ([[url path] rangeOfString:@"image" options:NSBackwardsSearch].location != NSNotFound) {
				StoryGalleryViewController *galleryVC = [[StoryGalleryViewController alloc] init];
				galleryVC.images = story.allImages;
				[self.navigationController pushViewController:galleryVC animated:YES];
				[galleryVC release];
				result = NO;
			} else if ([[url path] rangeOfString:@"bookmark" options:NSBackwardsSearch].location != NSNotFound) {
				// toggle bookmarked state
				self.story.bookmarked = [NSNumber numberWithBool:([self.story.bookmarked boolValue]) ? NO : YES];
				[CoreDataManager saveData];
			} else if ([[url path] rangeOfString:@"share" options:NSBackwardsSearch].location != NSNotFound) {
				[self share:nil];
			}
		}
	}
	return result;
}

- (NSString *)actionSheetTitle {
	return [NSString stringWithString:@"Share article with a friend"];
}

- (NSString *)emailSubject {
	return [NSString stringWithFormat:@"MIT News: %@", story.title];
}

- (NSString *)emailBody {
	return [NSString stringWithFormat:@"I thought you might be interested in this story found on the MIT News Office:\n\n\"%@\"\n%@\n\n%@\n\nTo view this story, click the link above or paste it into your browser.", story.title, story.summary, story.link];
}

- (NSString *)fbDialogPrompt {
	return nil;
}

- (NSString *)fbDialogAttachment {
	return [NSString stringWithFormat:
			@"{\"name\":\"%@\","
			"\"href\":\"%@\","
			//"\"caption\":\"%@\","
			"\"description\":\"%@\","
			"\"media\":["
			"{\"type\":\"image\","
			"\"src\":\"%@\","
			"\"href\":\"%@\"}]"
			//,"\"properties\":{\"another link\":{\"text\":\"Facebook home page\",\"href\":\"http://www.facebook.com\"}}"
			"}",
			story.title, story.link, story.summary, story.inlineImage.smallImage.url, story.link];
}

- (NSString *)twitterUrl {
	return [NSString stringWithFormat:@"http://%@/n/%@", MITMobileWebGetCurrentServerDomain(), [URLShortener compressedIdFromNumber:story.story_id]];
}

- (NSString *)twitterTitle {
	return story.title;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; 
}

- (void)dealloc {
	[storyView release];
    [story release];
    [super dealloc];
}

@end
