#import "MITWebviewCell.h"

@interface MITWebviewCell () <UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;

@end

@implementation MITWebviewCell

- (void)awakeFromNib
{
    // Initialization code
    self.webView.scrollView.scrollsToTop = NO;
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Public Methods

- (void)setHTMLString:(NSString *)htmlString
{
    [self.webView loadHTMLString:htmlString baseURL:nil];
}

#pragma mark - UIWebViewDelegate Methods

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // resize height and send delegate call
    
    if ([self.delegate respondsToSelector:@selector(webviewCellDidResize:)]) {
        [self.delegate webviewCellDidResize:self];
    }
}

@end
