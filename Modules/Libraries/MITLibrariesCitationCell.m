#import "MITLibrariesCitationCell.h"
#import "MITLibrariesCitation.h"

@interface MITLibrariesCitationCell () <UIWebViewDelegate>

@property (nonatomic, strong) MITLibrariesCitation *citation;
@property (nonatomic, weak) IBOutlet UILabel *citationLabel;
@property (nonatomic, weak) IBOutlet UIButton *shareButton;
@property (nonatomic, strong, readonly) NSCache *cache;

- (IBAction)shareButtonPressed:(id)sender;

@end

@implementation MITLibrariesCitationCell

- (void)awakeFromNib
{
    [super awakeFromNib];
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
    
    NSAttributedString *citationString = [self.cache objectForKey:citation.citation];
    if (!citationString) {
        NSData *citationData = [NSData dataWithBytes:[citation.citation cStringUsingEncoding:NSUTF8StringEncoding] length:citation.citation.length];
        NSAttributedString *citationString = [[NSAttributedString alloc] initWithData:citationData options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType} documentAttributes:NULL error:nil];
        [self.cache setObject:citationString forKey:citation.citation];
    }
    [self.citationLabel setAttributedText:citationString];
}

- (void)setContent:(MITLibrariesCitation *)citation
{
    [self setCitation:citation];
}

- (IBAction)shareButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(citationCellShareButtonPressed:)]) {
        [self.delegate citationCellShareButtonPressed:self.citationLabel.attributedText];
    }
}

- (NSCache *)cache
{
    static dispatch_once_t onceToken;
    static NSCache *sharedCache = nil;
    dispatch_once(&onceToken, ^{
        sharedCache = [NSCache new];
    });
    return sharedCache;
}

@end
