#import "StoryDetailViewController.h"
#import "MIT_MobileAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "NewsStory.h"
#import "CoreDataManager.h"
#import "Foundation+MITAdditions.h"
#import "StoryGalleryViewController.h"
#import "ConnectionDetector.h"

@interface StoryDetailViewController (Private)

- (void)showFacebookDialog;
- (void)postStoryToFacebook;

@end

@implementation StoryDetailViewController

@synthesize story, storyView, fbSession;

- (void)loadView {
    [super loadView]; // surprisingly necessary empty call to super due to the way memory warnings work
}

- (void)viewDidLoad {
    [super viewDidLoad];

    fbSession = nil;
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonItemStyleBordered target:self action:@selector(share:)] autorelease];

    self.view.opaque = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"news_story_template.html" relativeToURL:baseURL];
    
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
                     @"__TITLE__", @"__AUTHOR__", @"__DATE__", 
                     @"__THUMBNAIL_URL__", @"__THUMBNAIL_WIDTH__", @"__THUMBNAIL_HEIGHT__", @"__GALLERY_COUNT__", @"__DEK__", @"__BODY__", nil];
    
    NSArray *values = [NSArray arrayWithObjects:
                       story.title, story.author, postDate, thumbnailURL, thumbnailWidth, thumbnailHeight, galleryCountString, story.summary, story.body, nil];
    
    [htmlString replaceOccurrencesOfStrings:keys withStrings:values options:NSLiteralSearch];
    
    // mark story as read
    self.story.read = [NSNumber numberWithBool:YES];
    NSManagedObjectContext *context = [CoreDataManager managedObjectContext];
    id originalMergePolicy = [context mergePolicy];
    [context setMergePolicy:NSOverwriteMergePolicy];
    [CoreDataManager saveData];
    [context setMergePolicy:originalMergePolicy];
	
    storyView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    storyView.dataDetectorTypes = UIDataDetectorTypeLink;
    storyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    storyView.scalesPageToFit = NO;
	[self.view addSubview: storyView];
	storyView.delegate = self;
	[storyView loadHTMLString:htmlString baseURL:baseURL];
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	BOOL result = YES;
    
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		NSURL *url = [request URL];
        NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]];

		if ([[url path] rangeOfString:[baseURL path] options:NSAnchoredSearch].location == NSNotFound) {
            [[UIApplication sharedApplication] openURL:url];
            result = YES;
        } else {
            StoryGalleryViewController *galleryVC = [[StoryGalleryViewController alloc] init];
            galleryVC.images = story.allImages;
            [self.navigationController pushViewController:galleryVC animated:YES];
            [galleryVC release];
			result = NO;
		}
	}
	return result;
}

- (void)share:(id)sender {
	UIActionSheet *shareSheet = [[UIActionSheet alloc] initWithTitle:@"Share article with a friend" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Email", @"Facebook", nil];
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[UIApplication sharedApplication].delegate;
    [shareSheet showFromTabBar:appDelegate.tabBarController.tabBar];
    [shareSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		// Email
        NSString *emailSubject = [NSString stringWithFormat:@"MIT News: %@", story.title];
        
        NSString *emailBody = [NSString stringWithFormat:@"I thought you might be interested in this story found on the MIT News Office:\n\n\"%@\"\n%@\n\n%@\n\nTo view this story, click the link above or paste it into your browser.", story.title, story.summary, story.link];

        Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
        if ((mailClass != nil) && [mailClass canSendMail]) {
            
            MFMailComposeViewController *aController = [[MFMailComposeViewController alloc] init];
            aController.mailComposeDelegate = self;
            
            
            [aController setSubject:emailSubject];
            

            [aController setMessageBody:emailBody isHTML:NO];
            
            MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate presentAppModalViewController:aController animated:YES];
            [aController release];
            
        } else {
            NSString *mailtoString = [NSString stringWithFormat:@"mailto://?subject=%@&body=%@", 
                                    [emailSubject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                                    [emailBody stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
            
            NSURL *externURL = [NSURL URLWithString:mailtoString];
            if ([[UIApplication sharedApplication] canOpenURL:externURL])
                [[UIApplication sharedApplication] openURL:externURL];
        }
        
	}
    else if (buttonIndex == 1) {
		// Facebook session
		[self showFacebookDialog];
	}
}

#pragma mark -
#pragma mark MFMailComposeViewController delegation

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Facebook delegation

- (void)showFacebookDialog {
	BOOL resuming = NO;
	if (!self.fbSession) {
		NSString *apiKey = @"facebook_key";
		NSString *apiSecret = @"facebook_secret";
		self.fbSession = [FBSession sessionForApplication:apiKey secret:apiSecret delegate:self];
		resuming = [self.fbSession resume];
	}
	
	if (!self.fbSession.isConnected) {
		FBLoginDialog* dialog = [[[FBLoginDialog alloc] initWithSession:self.fbSession] autorelease];
		[dialog show];
	} else if (!resuming) {
		[self postStoryToFacebook];
	}
}

- (void)session:(FBSession*)session didLogin:(FBUID)uid {
	[self postStoryToFacebook];
}

- (void)postStoryToFacebook {
	FBStreamDialog* dialog = [[[FBStreamDialog alloc] init] autorelease];
	dialog.delegate = self;
	dialog.userMessagePrompt = nil;
	dialog.attachment = [NSString stringWithFormat:
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
	[dialog show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; 
}

- (void)dealloc {
	[storyView release];
    [story release];
    [fbSession release];
    [super dealloc];
}

@end
