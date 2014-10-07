#import "MITLibrariesCitationCell.h"
#import "MITLibrariesCitation.h"

@interface MITLibrariesCitationCell () <UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *citationWebView;
@property (nonatomic, weak) IBOutlet UIButton *shareButton;
@property (nonatomic, strong) void (^webViewLoadedCompletion)(void);

- (IBAction)shareButtonPressed:(id)sender;

@end

@implementation MITLibrariesCitationCell

- (void)awakeFromNib
{
    self.citationWebView.scrollView.scrollsToTop = NO;
    self.citationWebView.scrollView.scrollEnabled = NO;
    
    [self undelayContentTouchesInScrollViewSubviewsOfView:self];
}

// We need to do this so that the "Share" button doesn't have a delay when pressing
- (void)undelayContentTouchesInScrollViewSubviewsOfView:(UIView *)viewToTraverse
{
    for (UIView *subview in viewToTraverse.subviews) {
        if ([subview isKindOfClass:[UIScrollView class]]) {
            ((UIScrollView *)subview).delaysContentTouches = NO;
        }
        [self undelayContentTouchesInScrollViewSubviewsOfView:subview];
    }
}

- (void)setCitation:(MITLibrariesCitation *)citation
{
    _citation = citation;
    
    [self.citationWebView loadHTMLString:citation.citation baseURL:nil];
}

- (void)setCitation:(MITLibrariesCitation *)citation webViewLoadCompletion:(void (^)(void))completion
{
    if ([_citation isEqual:citation]) {
        completion();
        return;
    }
    
    if ([self.citationWebView isLoading]) {
        [self.citationWebView stopLoading];
    }
    
    self.webViewLoadedCompletion = completion;
    [self setCitation:citation];
}

- (IBAction)shareButtonPressed:(id)sender
{
    // TODO: Implement sharing once clarified
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (self.webViewLoadedCompletion) {
        self.webViewLoadedCompletion();
        self.webViewLoadedCompletion = nil;
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (self.webViewLoadedCompletion) {
        self.webViewLoadedCompletion();
        self.webViewLoadedCompletion = nil;
    }
}

#pragma mark - Sizing

+ (void)heightWithCitation:(MITLibrariesCitation *)citation tableWidth:(CGFloat)width completion:(void (^)(CGFloat height))completion
{
    /*
     We want to run all the sizing cell operations successively (since there is only one sizing cell), so we create our own dispatch queue.
     We also have to wait for the webview to load before determining the height, which is notified via a delegate method. So we
     use a semaphore to block the next operation from continuing before the previous one has been notified. We can't just run it
     synchronously or anything because we have to wait for the delegate call.
    */
    
    static dispatch_queue_t heightCalculationQueue;
    static dispatch_semaphore_t sizingCellSemaphore;
    
    static dispatch_once_t dispatchItemCreationToken;
    dispatch_once(&dispatchItemCreationToken, ^{
        heightCalculationQueue = dispatch_queue_create("MITLibrariesCitationCell_heightCalculationQueue", DISPATCH_QUEUE_SERIAL);
        sizingCellSemaphore = dispatch_semaphore_create(1);
    });
    
    dispatch_async(heightCalculationQueue, ^{
        dispatch_semaphore_wait(sizingCellSemaphore, DISPATCH_TIME_FOREVER);
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            CGRect frame = [self sizingCell].frame;
            frame.size.width = width;
            [self sizingCell].frame = frame;
            
            [[self sizingCell] layoutIfNeeded];
        });
        
        [[self sizingCell] setCitation:citation webViewLoadCompletion:^{
            NSString *result = [[self sizingCell].citationWebView stringByEvaluatingJavaScriptFromString:@"Math.max(document.body.scrollHeight, document.body.offsetHeight, document.documentElement.clientHeight, document.documentElement.scrollHeight, document.documentElement.offsetHeight);"];
            CGFloat height = [result floatValue] + 8 /* 4px top and bottom padding in constraints in nib */ + 1 /* 1px for separator */;
            NSLog(@"citation: %@, height: %f", citation.name, height);
            completion(height);
            dispatch_semaphore_signal(sizingCellSemaphore);
        }];
    });
}

+ (MITLibrariesCitationCell *)sizingCell
{
    static MITLibrariesCitationCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void (^instantiateFromNib)(void) = ^{
            UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
            sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
        };
        
        if ([NSThread isMainThread]) {
            instantiateFromNib();
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                instantiateFromNib();
            });
        }
    });
    
    return sizingCell;
}

@end
