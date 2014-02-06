#import "MITNewsStoryViewController.h"
#import "MITNewsStory.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"

#import "MITAdditions.h"
#import "UIImageView+WebCache.h"

@interface MITNewsStoryViewController () <UIWebViewDelegate,UIScrollViewDelegate>

@end

@implementation MITNewsStoryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.story) {
        self.story = (MITNewsStory*)[self.managedObjectContext objectWithID:[self.story objectID]];
    }

    self.bodyView.delegate = self;
    [self.bodyView loadHTMLString:[self htmlBody]
                          baseURL:nil];
    
    CGSize imageSize = self.coverImageView.bounds.size;
    MITNewsImageRepresentation *imageRepresentation = [self.story.coverImage bestRepresentationForSize:imageSize];

#if defined(DEBUG)
#warning Remove this section once the news API is updated
    NSURL *imageURL = [NSURL URLWithString:@"http://img.mit.edu/newsoffice/images/article_images/original/20140205163909-0.jpg"];
#else
    NSURL *imageURL = imageRepresentation.url;
#endif

    if (!imageURL) {
        self.coverImageViewHeightConstraint.constant = 0;
    } else {
        [self.coverImageView setImageWithURL:imageURL
                                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                       self.coverImageViewHeightConstraint.constant = MIN(self.coverImageViewHeightConstraint.constant,image.size.height);
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)shareButtonTapped:(id)sender
{
    
}

- (IBAction)unwindFromImageGallery:(UIStoryboardSegue *)sender
{
    DDLogVerbose(@"Unwinding from %@",[sender sourceViewController]);
}

- (NSString*)htmlBody
{
    NSURL *templateURL = [[NSBundle mainBundle] URLForResource:@"news/news_story_template" withExtension:@"html"];
    
    NSError *error = nil;
    NSMutableString *templateString = [NSMutableString stringWithContentsOfURL:templateURL encoding:NSUTF8StringEncoding error:&error];
    NSAssert(templateString, @"failed to load News story HTML template");
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM dd, y"];
    NSString *postDate = [dateFormatter stringFromDate:self.story.publishedAt];
    
    NSDictionary *templateBindings = @{@"__TITLE__": (self.story.title ? self.story.title : [NSNull null]),
                                       @"__AUTHOR__": (self.story.author ? self.story.author : [NSNull null]),
                                       @"__DATE__": (postDate ? postDate : [NSNull null]),
                                       @"__DEK__": (self.story.dek ? self.story.dek : [NSNull null]),
                                       @"__BODY__": (self.story.body ? self.story.body : [NSNull null]),
                                       @"__GALLERY_COUNT__": @([self.story.galleryImages count]),
                                       @"__BOOKMARKED__": @"",
                                       @"__THUMBNAIL_URL__": @"",
                                       @"__THUMBNAIL_WIDTH__": @"",
                                       @"__THUMBNAIL_HEIGHT__": @""};
    
    [templateBindings enumerateKeysAndObjectsUsingBlock:^(NSString *placeholder, id value, BOOL *stop) {
        if ([value isKindOfClass:[NSString class]]) {
            [templateString replaceOccurrencesOfString:placeholder
                                            withString:(NSString*)value
                                               options:0
                                                 range:NSMakeRange(0, [templateString length])];
        } else if ([value respondsToSelector:@selector(stringValue)]) {
            [templateString replaceOccurrencesOfString:placeholder
                                            withString:[value stringValue]
                                               options:0
                                                 range:NSMakeRange(0, [templateString length])];
        } else if ([value isKindOfClass:[NSNull class]]) {
            [templateString replaceOccurrencesOfString:placeholder
                                            withString:@""
                                               options:0
                                                 range:NSMakeRange(0, [templateString length])];
        }
    }];
    
    return templateString;
}


#pragma mark UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.bodyView.scrollView.scrollEnabled = NO;

    CGSize size = [self.bodyView sizeThatFits:CGSizeMake(CGRectGetWidth(self.scrollView.frame), 0)];
    self.bodyViewHeightConstraint.constant = size.height;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DDLogWarn(@"story view failed to load: %@", error);
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
