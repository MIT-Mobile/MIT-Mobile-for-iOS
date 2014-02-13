#import "MITNewsStoryViewController.h"
#import "MITNewsStory.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"
#import "MITNewsMediaGalleryViewController.h"

#import "MITAdditions.h"
#import "MITCoreDataController.h"
#import "UIImageView+WebCache.h"

@interface MITNewsStoryViewController () <UIWebViewDelegate,UIScrollViewDelegate,UIActivityItemSource>

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

    self.bodyView.scrollView.scrollEnabled = NO;
    self.bodyView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.bodyView loadHTMLString:[self htmlBody]
                          baseURL:nil];


    __block NSURL *imageURL = nil;
    [self.managedObjectContext performBlockAndWait:^{
        MITNewsStory *story = self.story;

        CGSize imageSize = self.coverImageView.bounds.size;
        imageSize.height = 213.;
        MITNewsImageRepresentation *imageRepresentation = [story.coverImage bestRepresentationForSize:imageSize];
        imageURL = imageRepresentation.url;
    }];

    if (imageURL) {
        [self.coverImageView setImageWithURL:imageURL
                                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                       [self.view setNeedsUpdateConstraints];
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];

    CGSize size = [self.bodyView sizeThatFits:CGSizeMake(CGRectGetWidth(self.scrollView.frame), 0)];
    self.bodyViewHeightConstraint.constant = size.height;

    if (self.coverImageView.image) {
        // Using 213 here because all the images from the News office should be around a
        // 3:2 aspect ratio and, given a screen width of 320pt, a height of 213pt is within
        // a point or two.
        // TODO: If the width is going to change calculate the dimentions using the image view bounds instead of hardcoding the height
        // (bskinner - 2014.02.07)
        self.coverImageViewHeightConstraint.constant = 213.;
    } else {
        self.coverImageViewHeightConstraint.constant = 0;
    }
}

- (IBAction)shareButtonTapped:(id)sender
{
    NSMutableArray *items = [NSMutableArray arrayWithObject:self];
    [self.managedObjectContext performBlockAndWait:^{
        [items addObject:self.story.sourceURL];
    }];

    UIActivityViewController *sharingViewController = [[UIActivityViewController alloc] initWithActivityItems:items
                                                                                        applicationActivities:nil];
    sharingViewController.excludedActivityTypes = @[UIActivityTypePrint,
                                                    UIActivityTypeAssignToContact,
                                                    UIActivityTypeSaveToCameraRoll];

    [self presentViewController:sharingViewController animated:YES completion:nil];
}

- (IBAction)unwindFromImageGallery:(UIStoryboardSegue *)sender
{
    DDLogVerbose(@"Unwinding from %@",[sender sourceViewController]);
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"showMediaGallery"]) {
        __block NSInteger numberOfGalleryImages = 0;
        [self.managedObjectContext performBlockAndWait:^{
            numberOfGalleryImages = [self.story.galleryImages count];
        }];

        return (numberOfGalleryImages > 0);
    } else {
        return YES;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showMediaGallery"]) {
        MITNewsMediaGalleryViewController *viewController = (MITNewsMediaGalleryViewController*)[segue destinationViewController];

        NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        managedObjectContext.parentContext = self.managedObjectContext;
        viewController.managedObjectContext = managedObjectContext;

        [self.managedObjectContext performBlockAndWait:^{
            viewController.galleryImages = [self.story.galleryImages array];
        }];

    }
}

- (NSString*)htmlBody
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM dd, y"];
    });

    NSURL *templateURL = [[NSBundle mainBundle] URLForResource:@"news/news_story_template" withExtension:@"html"];
    
    NSError *error = nil;
    NSMutableString *templateString = [NSMutableString stringWithContentsOfURL:templateURL encoding:NSUTF8StringEncoding error:&error];
    NSAssert(templateString, @"failed to load News story HTML template");

    __block NSDictionary *templateBindings = nil;
    [self.managedObjectContext performBlockAndWait:^{
        MITNewsStory *story = self.story;

        NSString *postDate = [dateFormatter stringFromDate:story.publishedAt];

        templateBindings = @{@"__TITLE__": (story.title ? story.title : [NSNull null]),
                             @"__AUTHOR__": (story.author ? story.author : [NSNull null]),
                             @"__DATE__": (postDate ? postDate : [NSNull null]),
                             @"__DEK__": (story.dek ? story.dek : [NSNull null]),
                             @"__BODY__": (story.body ? story.body : [NSNull null]),
                             @"__GALLERY_COUNT__": @([story.galleryImages count]),
                             @"__BOOKMARKED__": @"",
                             @"__THUMBNAIL_URL__": @"",
                             @"__THUMBNAIL_WIDTH__": @"",
                             @"__THUMBNAIL_HEIGHT__": @""};
    }];


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

- (MITNewsStory*)story
{
    if (_story) {
        if (_story.managedObjectContext != self.managedObjectContext) {
            [self.managedObjectContext performBlockAndWait:^{
                _story = (MITNewsStory*)[self.managedObjectContext objectWithID:[_story objectID]];
            }];
        }
    }

    return _story;
}


#pragma mark UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.view setNeedsUpdateConstraints];
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

#pragma mark UIActivityItemSource
- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return [NSString string];
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    DDLogVerbose(@"Activity type: %@", activityType);
    if ([activityType isEqualToString:@"com.apple.UIKit.activity.CopyToPasteboard"]) {
        return self.story.sourceURL;
    } else {
        return self.story.title;
    }
}
@end
