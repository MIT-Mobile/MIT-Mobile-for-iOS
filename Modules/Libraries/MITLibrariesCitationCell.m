#import "MITLibrariesCitationCell.h"
#import "MITLibrariesCitation.h"

@interface MITLibrariesCitationCell () <UIWebViewDelegate>

@property (nonatomic, strong) MITLibrariesCitation *citation;
@property (nonatomic, weak) IBOutlet UILabel *citationLabel;
@property (nonatomic, weak) IBOutlet UIButton *shareButton;

- (IBAction)shareButtonPressed:(id)sender;

@end

@implementation MITLibrariesCitationCell

- (void)awakeFromNib
{
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
    
    NSData *citationData = [NSData dataWithBytes:[citation.citation cStringUsingEncoding:NSUTF8StringEncoding] length:citation.citation.length];
    NSMutableAttributedString *citationString = [[NSMutableAttributedString alloc] initWithData:citationData options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType} documentAttributes:NULL error:nil];

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

@end
