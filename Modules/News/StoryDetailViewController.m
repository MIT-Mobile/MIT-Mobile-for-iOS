#import <QuartzCore/QuartzCore.h>

#import "StoryDetailViewController.h"

#import "MITConstants.h"
#import "ConnectionDetector.h"
#import "CoreDataManager.h"
#import "Foundation+MITAdditions.h"
#import "MFMailComposeViewController+RFC2368.h"
#import "MIT_MobileAppDelegate.h"
#import "MITMobileServerConfiguration.h"
#import "NewsStory.h"
#import "StoryListViewController.h"
#import "StoryGalleryViewController.h"
#import "URLShortener.h"

@interface StoryDetailViewController ()
@property (strong) UISegmentedControl *storyPager;
@property (strong) UIWebView *storyView;
@end

@implementation StoryDetailViewController
{
	StoryListViewController *newsController;
    NewsStory *story;
}

@synthesize newsController, story;
@synthesize storyView = _storyView;
@synthesize storyPager = _storyPager;

- (void)dealloc
{
    self.newsController = nil;
    self.storyView = nil;
    self.story = nil;
    self.storyPager = nil;
    
    [super dealloc];
}

- (void)loadView {
    CGRect mainFrame = [[UIScreen mainScreen] applicationFrame];
    UIView *mainView = [[[UIView alloc] initWithFrame:mainFrame] autorelease];
    mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
    mainView.autoresizesSubviews = YES;
    mainView.backgroundColor = [UIColor whiteColor];

    {
        NSArray *pagerItems = [NSArray arrayWithObjects:
                               [UIImage imageNamed:MITImageNameUpArrow], 
                               [UIImage imageNamed:MITImageNameDownArrow], 
                               nil];
        UISegmentedControl *pager = [[[UISegmentedControl alloc] initWithItems:pagerItems] autorelease];
        
        pager.momentary = YES;
        pager.segmentedControlStyle = UISegmentedControlStyleBar;
        pager.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                  UIViewAutoresizingFlexibleHeight |
                                  UIViewAutoresizingFlexibleBottomMargin);
        pager.frame = CGRectMake(0, 0, 80.0, CGRectGetHeight(pager.frame));
        
        [pager setEnabled:NO forSegmentAtIndex:0];
        [pager setEnabled:NO forSegmentAtIndex:1];
        
        [pager addTarget:self
                  action:@selector(didPressNavButton:)
        forControlEvents:UIControlEventValueChanged];
        
        UIBarButtonItem *segmentItem = [[[UIBarButtonItem alloc] initWithCustomView:pager] autorelease];
        self.navigationItem.rightBarButtonItem = segmentItem;
        self.storyPager = pager;
    }
    
    {
        UIWebView *webView = [[[UIWebView alloc] initWithFrame:mainView.bounds] autorelease];
        webView.dataDetectorTypes = UIDataDetectorTypeLink;
        webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                    UIViewAutoresizingFlexibleHeight);
        webView.scalesPageToFit = NO;
        webView.delegate = self;
        [mainView addSubview:webView];
        self.storyView = webView;
    }
    
    [self setView:mainView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.shareDelegate = self;
	
	if (self.story) {
		[self displayStory:self.story];
	}
}

- (void)displayStory:(NewsStory *)aStory {
	[self.storyPager setEnabled:[self.newsController canSelectPreviousStory] forSegmentAtIndex:0];
	[self.storyPager setEnabled:[self.newsController canSelectNextStory] forSegmentAtIndex:1];

	NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"news/news_story_template.html" relativeToURL:baseURL];
    
    NSError *error = nil;
    NSMutableString *htmlString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!htmlString) {
        return;
    }
    
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateFormat:@"MMM dd, y"];
    NSString *postDate = [dateFormatter stringFromDate:story.postDate];
    
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
	[self.storyView loadHTMLString:htmlString baseURL:baseURL];
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

        if ([[url scheme] caseInsensitiveCompare:@"mailto"] == NSOrderedSame) {
            if ([MFMailComposeViewController canSendMail]) {
                MFMailComposeViewController *mailController = [[[MFMailComposeViewController alloc] initWithMailToURL:url] autorelease];
                mailController.mailComposeDelegate = self;
                [self presentModalViewController:mailController animated:YES];
            }
        } else if ([[url path] rangeOfString:[baseURL path] options:NSAnchoredSearch].location == NSNotFound) {
            [[UIApplication sharedApplication] openURL:url];
            result = NO;
        } else {
            if ([[url path] rangeOfString:@"image" options:NSBackwardsSearch].location != NSNotFound) {
                StoryGalleryViewController *galleryVC = [[[StoryGalleryViewController alloc] init] autorelease];
                galleryVC.images = story.allImages;
                [self.navigationController pushViewController:galleryVC animated:YES];
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
	return @"Share article with a friend";
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

#pragma mark MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    [self dismissModalViewControllerAnimated:YES];
}
@end
