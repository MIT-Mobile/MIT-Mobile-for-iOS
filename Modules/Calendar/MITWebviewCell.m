#import "MITWebviewCell.h"

static CGFloat const kWebViewHorizontalPadding = 8.0;
static CGFloat const kWebViewVerticalPadding = 6.0;

@interface MITWebviewCell () <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;

@end

@implementation MITWebviewCell

- (void)awakeFromNib
{
    // Initialization code
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self recreateWebView];
}

- (void)recreateWebView
{
    [self.webView removeFromSuperview];
    
    CGFloat newWebviewHeight = MAX(0, self.bounds.size.width - (2 * kWebViewHorizontalPadding));
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(kWebViewHorizontalPadding, kWebViewVerticalPadding, newWebviewHeight, 32)];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.webView];
    
    self.webView.scrollView.scrollsToTop = NO;
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.delegate = self;
}

- (void)addWebViewConstraints
{
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(<=horizontalPadding)-[webView]-(<=horizontalPadding)-|" options:0 metrics:@{@"horizontalPadding": [NSNumber numberWithFloat:kWebViewHorizontalPadding]} views:@{@"webView": self.webView}]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(<=verticalPadding)-[webView]-(<=verticalPadding)-|" options:0 metrics:@{@"verticalPadding": [NSNumber numberWithFloat:kWebViewVerticalPadding]} views:@{@"webView": self.webView}]];
}

#pragma mark - Public Methods

- (void)setHtmlString:(NSString *)htmlString
{
    if ([htmlString isEqualToString:_htmlString]) {
        return;
    }
    
    _htmlString = htmlString;
    
    [self recreateWebView];
    [self.webView loadHTMLString:htmlString baseURL:nil];
}

#pragma mark - UIWebViewDelegate Methods

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (webView.isLoading) {
        return;
    }
    
    CGFloat newHeight = self.webView.scrollView.contentSize.height;
    
    [self addWebViewConstraints];
    
    if (self.webView.frame.size.height != newHeight && [self.delegate respondsToSelector:@selector(webviewCellDidResize:toHeight:)]) {
        [self.delegate webviewCellDidResize:self toHeight:(newHeight + (2 * kWebViewVerticalPadding))];
    }
}

@end
