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
#import "UIKit+MITAdditions.h"

@interface StoryDetailViewController ()
@property (strong) UISegmentedControl *storyPager;
@property (strong) UIWebView *storyView;
@end

@implementation StoryDetailViewController
- (void)loadView {
    CGRect mainFrame = [[UIScreen mainScreen] applicationFrame];
    UIView *mainView = [[UIView alloc] initWithFrame:mainFrame];
    mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
    mainView.autoresizesSubviews = YES;
    mainView.backgroundColor = [UIColor whiteColor];

    {
        NSArray *pagerItems = @[[UIImage imageNamed:MITImageNameUpArrow],
                                [UIImage imageNamed:MITImageNameDownArrow]];
        UISegmentedControl *pager = [[UISegmentedControl alloc] initWithItems:pagerItems];
        
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
        
        UIBarButtonItem *segmentItem = [[UIBarButtonItem alloc] initWithCustomView:pager];
        self.navigationItem.rightBarButtonItem = segmentItem;
        self.storyPager = pager;
    }
    
    {
        UIWebView *webView = [[UIWebView alloc] initWithFrame:mainView.bounds];
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

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
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
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM dd, y"];
    NSString *postDate = [dateFormatter stringFromDate:self.story.postDate];
    
    NSString *thumbnailURL = self.story.inlineImage.smallImage.url;
    if (!thumbnailURL) {
        thumbnailURL = @"";
    }
    
    NSString *thumbnailWidth = [self.story.inlineImage.smallImage.width stringValue];
    if (!thumbnailWidth) {
        thumbnailWidth = @"";
    }
    
    NSString *thumbnailHeight = [self.story.inlineImage.smallImage.height stringValue];
    if (!thumbnailHeight) {
        thumbnailHeight = @"";
    }
    
    NSInteger galleryCount = [self.story.galleryImages count];
    if (self.story.inlineImage) {
        galleryCount++;
    }
    
    // if not connected, pretend there are no images
    NSString *galleryCountString = ([ConnectionDetector isConnected]) ? [@(galleryCount) stringValue] : @"0";
	NSString *isBookmarked = ([self.story.bookmarked boolValue]) ? @"on" : @"";
    
    NSDictionary *replacements = @{@"__TITLE__" : self.story.title,
                                   @"__AUTHOR__" : self.story.author,
                                   @"__DATE__" : postDate,
                                   @"__BOOKMARKED__" : isBookmarked,
                                   @"__THUMBNAIL_URL__" : thumbnailURL,
                                   @"__THUMBNAIL_WIDTH__" : thumbnailWidth,
                                   @"__THUMBNAIL_HEIGHT__" : thumbnailHeight,
                                   @"__GALLERY_COUNT__" : galleryCountString,
                                   @"__DEK__" : self.story.summary,
                                   @"__BODY__" : self.story.body};
    
    [htmlString replaceOccurrencesOfStrings:[replacements allKeys]
                                withStrings:[replacements allValues]
                                    options:NSLiteralSearch];
    
    // mark story as read
    self.story.read = @(YES);
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
                MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] initWithMailToURL:url];
                mailController.mailComposeDelegate = self;
                [self presentModalViewController:mailController animated:YES];
            }
        } else if ([[url path] rangeOfString:[baseURL path] options:NSAnchoredSearch].location == NSNotFound) {
            [[UIApplication sharedApplication] openURL:url];
            result = NO;
        } else {
            if ([[url path] rangeOfString:@"image" options:NSBackwardsSearch].location != NSNotFound) {
                StoryGalleryViewController *galleryVC = [[StoryGalleryViewController alloc] init];
                galleryVC.images = self.story.allImages;
                [self.navigationController pushViewController:galleryVC animated:YES];
                result = NO;
            } else if ([[url path] rangeOfString:@"bookmark" options:NSBackwardsSearch].location != NSNotFound) {
                // toggle bookmarked state
                self.story.bookmarked = @(![self.story.bookmarked boolValue]);
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
	return [NSString stringWithFormat:@"MIT News: %@", self.story.title];
}

- (NSString *)emailBody {
	return [NSString stringWithFormat:@"I thought you might be interested in this story found on the MIT News Office:\n\n\"%@\"\n%@\n\n%@\n\nTo view this story, click the link above or paste it into your browser.", self.story.title, self.story.summary, self.story.link];
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
			self.story.title, self.story.link, self.story.summary, self.story.inlineImage.smallImage.url, self.story.link];
}

- (NSString *)twitterUrl {
	return [NSString stringWithFormat:@"http://%@/n/%@", MITMobileWebGetCurrentServerDomain(), [URLShortener compressedIdFromNumber:self.story.story_id]];
}

- (NSString *)twitterTitle {
	return self.story.title;
}

#pragma mark MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    [self dismissModalViewControllerAnimated:YES];
}
@end
