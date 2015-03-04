#import "MITNewsStoryViewController.h"
#import "MITNewsStory.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"
#import "MITNewsMediaGalleryViewController.h"

#import "MITAdditions.h"
#import "MITCoreDataController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface MITNewsStoryViewController () <UIWebViewDelegate,UIScrollViewDelegate,UIActivityItemSource>
@property (nonatomic,strong) MITNewsStory *story;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nextStoryImageWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nextStoryImageHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nextStoryImageTitleHorizontalConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nextStoryDekTitleVerticalContraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nextStoryDateBottomVerticalConstraint;

@property (weak, nonatomic) IBOutlet UILabel *nextStoryTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *nextStoryDekLabel;
@property (weak, nonatomic) IBOutlet UILabel *nextStoryDateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *nextStoryImageView;
@property (weak, nonatomic) IBOutlet UILabel *nextStoryNextStoryLabel;
@property (weak, nonatomic) IBOutlet UIView *nextStoryView;
@property (nonatomic) CGFloat scrollPosition;
@property (nonatomic) CGFloat pageHeight;
@property (nonatomic) CGFloat beforeRotateBodyViewHeightConstraint;

@property (weak, nonatomic) MITNewsMediaGalleryViewController *weakMITNewsMediaGalleryViewController;

@end

@implementation MITNewsStoryViewController {
    NSManagedObjectID *_storyObjectID;
}
@synthesize story = _story;

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
    self.bodyView.scrollView.bounces = NO;
    self.bodyView.delegate = self;
    [self updateNavigationItem:YES];
    
    //Clearing placeholders on NEXT STORY
    self.nextStoryImageView.image = nil;
    self.nextStoryTitleLabel.text = nil;
    self.nextStoryDekLabel.text = nil;
    self.nextStoryDateLabel.text = nil;
    self.nextStoryNextStoryLabel.text = nil;
}

- (void)updateNavigationItem:(BOOL)animated
{
    NSMutableArray *rightBarItems = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonTapped:)];
    [rightBarItems addObject:shareItem];
    
    [self.navigationItem setRightBarButtonItems:rightBarItems animated:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.bodyViewHeightConstraint.constant = CGRectGetHeight(self.scrollView.frame);
    
    [self.bodyView loadHTMLString:[self htmlBody]
                          baseURL:nil];

    if (!UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {

        __block NSURL *imageURL = nil;
        [self.managedObjectContext performBlockAndWait:^{
            if (self.story) {
                CGSize imageSize = self.scrollView.bounds.size;
                imageSize.height = 213.;
                
                MITNewsImageRepresentation *imageRepresentation = [self.story.coverImage bestRepresentationForSize:imageSize];
                imageURL = imageRepresentation.url;
            }
        }];
        
        if (imageURL) {
            [self.coverImageView sd_setImageWithURL:imageURL
                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                           [self.view setNeedsUpdateConstraints];
                                       }];
        }

    }
    
    self.weakMITNewsMediaGalleryViewController = nil;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];

    CGRect frame = self.bodyView.frame;
    frame.size.height = 1;
    self.bodyView.frame = frame;
    CGSize fittingSize = [self.bodyView sizeThatFits:CGSizeZero];
    frame.size = fittingSize;
    self.bodyView.frame = frame;
    
    CGSize size = [self.bodyView sizeThatFits:CGSizeMake(CGRectGetWidth(self.scrollView.frame), 0)];
    self.bodyViewHeightConstraint.constant = size.height;
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        if (self.coverImageView.image) {
            
            CGFloat imageRatio = self.coverImageView.image.size.width / self.coverImageView.image.size.height;
            
            CGRect screenRect = self.view.bounds;
            CGFloat screenWidth = screenRect.size.width;
            CGFloat screenHeight = screenRect.size.height;
            CGFloat maxWidth = screenHeight < screenWidth ? screenHeight : screenWidth;
            
            self.coverImageViewHeightConstraint.constant = maxWidth / imageRatio;
        } else {
            self.coverImageViewHeightConstraint.constant = 0;
        }
    } else {
        if (self.nextStoryImageView.image != NULL) {
            self.nextStoryImageHeightConstraint.constant = 60;
            self.nextStoryImageWidthConstraint.constant = 90;
            self.nextStoryImageTitleHorizontalConstraint.constant = 8;
        } else {
            self.nextStoryImageHeightConstraint.constant = 0;
            self.nextStoryImageWidthConstraint.constant = 0;
            self.nextStoryImageTitleHorizontalConstraint.constant = 0;
        }
    }
    if (!self.nextStoryDekLabel.text) {
        self.nextStoryDekTitleVerticalContraint.constant = 0;
    }
}

- (IBAction)shareButtonTapped:(id)sender
{
    if (self.story) {
        NSMutableArray *items = [NSMutableArray arrayWithObject:self];
        [self.managedObjectContext performBlockAndWait:^{
            NSURL *sourceURL = self.story.sourceURL;
            if (sourceURL) {
                [items addObject:sourceURL];
            }
        }];

        UIActivityViewController *sharingViewController = [[UIActivityViewController alloc] initWithActivityItems:items
                                                                                            applicationActivities:nil];
        sharingViewController.excludedActivityTypes = @[UIActivityTypePrint,
                                                        UIActivityTypeAssignToContact];
        
        [sharingViewController setValue:[NSString stringWithFormat:@"MIT News: %@",self.story.title] forKeyPath:@"subject"];

        if ([sharingViewController respondsToSelector:@selector(popoverPresentationController)]) {
            sharingViewController.popoverPresentationController.barButtonItem = sender;
        }
        [self presentViewController:sharingViewController animated:YES completion:nil];
    }
}

- (IBAction)unwindFromImageGallery:(UIStoryboardSegue *)sender
{
    DDLogVerbose(@"Unwinding from %@",[sender sourceViewController]);
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if (self.story && [identifier isEqualToString:@"showMediaGallery"]) {
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
        self.weakMITNewsMediaGalleryViewController = viewController;
        [self setNeedsStatusBarAppearanceUpdate];
        NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        managedObjectContext.parentContext = self.managedObjectContext;
        viewController.managedObjectContext = managedObjectContext;

        [self.managedObjectContext performBlockAndWait:^{
            viewController.galleryImages = [self.story.galleryImages array];
            viewController.storyLink = self.story.sourceURL;
            viewController.storyTitle = self.story.title;
        }];
    }
}


- (void)setStory:(MITNewsStory*)story
{
    NSManagedObjectID *newStoryObjectID = [story objectID];
    if (newStoryObjectID && ![newStoryObjectID isEqual:_storyObjectID]) {
        _storyObjectID = newStoryObjectID;
    }
    
    _story = nil;
}

- (MITNewsStory*)story
{
    if (!_story && _storyObjectID) {
        [self.managedObjectContext performBlockAndWait:^{
            NSError *error = nil;
            _story = (MITNewsStory*)[self.managedObjectContext existingObjectWithID:_storyObjectID error:&error];

            if (error) {
                DDLogError(@"failed to retreive object for id '%@': %@",_storyObjectID,error);
            }
        }];
    }
    
    return _story;
}

- (NSString*)htmlBody
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM dd, y"];
    });
    
    NSURL *templateURL = nil;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        templateURL = [[NSBundle mainBundle] URLForResource:@"news/news_story_iPad_template" withExtension:@"html"];
    } else {
        templateURL = [[NSBundle mainBundle] URLForResource:@"news/news_story_template" withExtension:@"html"];
    }
    
    NSError *error = nil;
    NSMutableString *templateString = [NSMutableString stringWithContentsOfURL:templateURL encoding:NSUTF8StringEncoding error:&error];
    NSAssert(templateString, @"failed to load News story HTML template");

    __block NSDictionary *templateBindings = nil;
    [self.managedObjectContext performBlockAndWait:^{
        MITNewsStory *story = self.story;
        if (story) {
            NSString *postDate = @"";
            NSDate *publishedAt = story.publishedAt;
            if (publishedAt) {
                postDate = [dateFormatter stringFromDate:publishedAt];
            }
            
            MITNewsImageRepresentation *representation = [story.coverImage bestRepresentationForSize:CGSizeMake(400, 400)];
            
            CGSize resizedImage = CGSizeZero;
            if (representation) {
                resizedImage = [self scaledSizeForSize:CGSizeMake([representation.width doubleValue], [representation.height doubleValue]) withMaximumSize:CGSizeMake(368, 400)];
            }
            templateBindings = @{@"__TITLE__": (story.title ? story.title : [NSNull null]),
                                 @"__AUTHOR__": (story.author ? story.author : [NSNull null]),
                                 @"__DATE__": (postDate ? postDate : [NSNull null]),
                                 @"__DEK__": (story.dek ? story.dek : [NSNull null]),
                                 @"__BODY__": (story.body ? story.body : [NSNull null]),
                                 @"__GALLERY_COUNT__": (representation ? @"1" : @"0"),
                                 @"__BOOKMARKED__": @"",
                                 @"__THUMBNAIL_URL__": @"",
                                 @"__THUMBNAIL_WIDTH__": @"",
                                 @"__THUMBNAIL_HEIGHT__": @"",
                                 @"__GALLERY_URL__" : ([representation.url absoluteString] ? [representation.url absoluteString] : [NSNull null]),
                                 @"__GALLERY_WIDTH__" : ([NSString stringWithFormat:@"%f",resizedImage.width] ? [NSString stringWithFormat:@"%f",resizedImage.width] : @"0"),
                                 @"__GALLERY_HEIGHT__" : ([NSString stringWithFormat:@"%f",resizedImage.height] ? [NSString stringWithFormat:@"%f",resizedImage.height] : @"0"),
                                 @"__GALLERY_DESCRIPTION__" : (story.coverImage.descriptionText ? story.coverImage.descriptionText : [NSNull null]),
                                 @"__GALLERY_CREDIT__" : (story.coverImage.credits ? story.coverImage.credits : [NSNull null])
                                 };
        }
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

- (CGSize)scaledSizeForSize:(CGSize)targetSize withMaximumSize:(CGSize)maximumSize
{
    if ((targetSize.width > maximumSize.width) || (targetSize.height > maximumSize.height)) {
        CGFloat xScale = maximumSize.width / targetSize.width;
        CGFloat yScale = maximumSize.height / targetSize.height;
        
        CGFloat scale = MIN(xScale,yScale);
        return CGSizeMake(ceil(targetSize.width * scale), ceil(targetSize.height * scale));
    } else {
        return targetSize;
    }
}

- (void)willRotateToInterfaceOrientation: (UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    self.scrollPosition = self.scrollView.contentOffset.y;
    self.pageHeight = self.scrollView.contentSize.height;
    self.beforeRotateBodyViewHeightConstraint = self.bodyViewHeightConstraint.constant;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
    CGFloat changeInScrollViewHeight = self.bodyViewHeightConstraint.constant - self.beforeRotateBodyViewHeightConstraint;
    if (self.pageHeight != 0 ) {
        self.scrollView.contentOffset = CGPointMake(0, (self.pageHeight + changeInScrollViewHeight) * (self.scrollPosition / self.pageHeight));
    }
}

#pragma mark UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // Set the height to '1' here so that when we update the
    // view constraints in updateViewConstraints, the web view
    // returns the correct minimum size it needs to fit the content
    // when sizeThatFitsSize: is called. '1' may or may not be a magic
    // number here; using either '0' or leaving the frame at its
    // default sizing results in incorrect behavior
    CGRect frame = webView.frame;
    frame.size.height = 1;
    webView.frame = frame;
    
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];

    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
    
    [self setupNextStory];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DDLogWarn(@"story view failed to load: %@", error);
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL result = YES;
    if (navigationType == UIWebViewNavigationTypeOther) {
        NSURL *url = [request URL];
        if ([[url relativeString] isEqualToString:@"mitmobilenews://opengallery"])
        {
            [self performSegueWithIdentifier:@"showMediaGallery" sender:nil];
            return NO;
        }
        
    } else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSURL *url = [request URL];
        NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]];
        
        if ([[url path] rangeOfString:[baseURL path] options:NSAnchoredSearch].location == NSNotFound) {
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
            
            result = NO;
        }
    }
    
    return result;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (IBAction)touchNextStoryView:(id)sender
{
    [self storyAfterStory:self.story completion:^(MITNewsStory *nextStory, NSError *error) {
        if (nextStory) {
            
            self.pageHeight = 0;
            self.scrollPosition = 0;
            
            [self setStory:nextStory];
            
            [self.bodyView loadHTMLString:[self htmlBody]
                                  baseURL:nil];
        }
    }];
}

- (void)storyAfterStory:(MITNewsStory*)story completion:(void(^)(MITNewsStory *nextStory, NSError *error))block
{
    [self.delegate storyAfterStory:story completion:^(MITNewsStory *nextStory, NSError *error) {
        if (block) {
            block(nextStory, error);
        }
    }];
}

- (void)setupNextStory
{
    self.nextStoryImageView.image = nil;
    self.nextStoryTitleLabel.text = nil;
    self.nextStoryDekLabel.text = nil;
    self.nextStoryDateLabel.text = nil;
    self.nextStoryNextStoryLabel.text = nil;
    [self storyAfterStory:self.story completion:^(MITNewsStory *nextStory, NSError *error) {
        if (nextStory) {
            __block NSString *title = nil;
            __block NSString *dek = nil;
            __block NSURL *imageURL = nil;
            [nextStory.managedObjectContext performBlockAndWait:^{
                
                title = nextStory.title;
                dek = nextStory.dek;
                
                CGSize idealImageSize = self.nextStoryImageView.frame.size;
                
                MITNewsImageRepresentation *representation = [nextStory.coverImage bestRepresentationForSize:idealImageSize];
                if (representation) {
                    imageURL = representation.url;
                }
            }];
            
            if (title) {
                NSError *error = nil;
                NSString *titleContent = [title stringBySanitizingHTMLFragmentWithPermittedElementNames:nil error:&error];
                if (!titleContent) {
                    DDLogWarn(@"failed to sanitize title, falling back to the original content: %@",error);
                    titleContent = title;
                }
                self.nextStoryTitleLabel.text = titleContent;
                
            } else {
                self.nextStoryTitleLabel.text = nil;
            }
            if (dek) {
                NSError *error = nil;
                NSString *dekContent = [dek stringBySanitizingHTMLFragmentWithPermittedElementNames:nil error:&error];
                if (error) {
                    DDLogWarn(@"failed to sanitize dek, falling back to the original content: %@",error);
                    dekContent = dek;
                }
                
                self.nextStoryDekLabel.text = dekContent;
            } else {
                self.nextStoryDekLabel.text = nil;
            }
            
            if (imageURL) {
                MITNewsStory *currentStory = nextStory;
                __weak MITNewsStoryViewController *weakSelf = self;
                [self.nextStoryImageView sd_setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                    [self.view setNeedsUpdateConstraints];

                    MITNewsStoryViewController *blockSelf = weakSelf;
                    if (blockSelf && (blockSelf->_story == currentStory)) {
                        if (error) {
                            blockSelf.nextStoryImageView.image = nil;
                        }
                    }
                }];
            } else {
                self.nextStoryImageView.image = nil;
            }
            static NSDateFormatter *dateFormatter = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"MMM dd, y"];
            });
            
            NSURL *templateURL = nil;
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                templateURL = [[NSBundle mainBundle] URLForResource:@"news/news_story_iPad_template" withExtension:@"html"];
            } else {
                templateURL = [[NSBundle mainBundle] URLForResource:@"news/news_story_template" withExtension:@"html"];
            }
            
            NSError *error = nil;
            NSMutableString *templateString = [NSMutableString stringWithContentsOfURL:templateURL encoding:NSUTF8StringEncoding error:&error];
            NSAssert(templateString, @"failed to load News story HTML template");
            
            NSString *postDate = @"";
            NSDate *publishedAt = nextStory.publishedAt;
            if (publishedAt) {
                postDate = [dateFormatter stringFromDate:publishedAt];
            }
            self.nextStoryDateLabel.text = postDate;
            self.nextStoryNextStoryLabel.text = @"NEXT STORY";
        } else {
            [self.nextStoryImageView sd_cancelCurrentImageLoad];
            self.nextStoryImageView.image = nil;
            self.nextStoryTitleLabel.text = nil;
            self.nextStoryDekLabel.text = nil;
            self.nextStoryDateLabel.text = nil;
            self.nextStoryNextStoryLabel.text = nil;
        }
    }];
    
    
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

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return self.weakMITNewsMediaGalleryViewController;
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.weakMITNewsMediaGalleryViewController;
}

@end
