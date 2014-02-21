#import "BookDetailTableViewCell.h"
#import <CoreText/CoreText.h>

#define BOOK_DETAIL_CELL_MARGIN 10

const CGFloat BookDetailFontSizeTitle = 18.0;
const CGFloat BookDetailFontSizeDefault = 15.0;

@implementation BookDetailTableViewCell
+ (CGSize)sizeForDisplayString:(NSAttributedString *)displayString tableView:(UITableView *)tableView
{
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)displayString);
    
    CGSize limitSize = CGSizeMake(CGRectGetWidth(tableView.bounds) - BOOK_DETAIL_CELL_MARGIN * 2, 2009);
    CGSize fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,
                                                                  CFRangeMake(0, 0),
                                                                  NULL,
                                                                  limitSize,
                                                                  NULL);
    CFRelease(framesetter);
    
    return fitSize;
}

+ (NSAttributedString *)displayStringWithTitle:(NSString *)title
                                      subtitle:(NSString *)subtitle
                                     separator:(NSString *)separator
                                      fontSize:(CGFloat)fontSize
{
    if (!separator) {
        separator = @"";
    }
    if (!title) {
        title = @"";
    }
    if (!subtitle) {
        subtitle = @"";
    }
    
    NSString *rawString = [NSString stringWithFormat:@"%@%@%@", title, separator, subtitle];
    NSUInteger titleLength = title.length + separator.length;
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    CTFontRef ctFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
    
    UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSize];
    CTFontRef ctBoldFont = CTFontCreateWithName((__bridge CFStringRef)boldFont.fontName, boldFont.pointSize, NULL);
    
    NSMutableAttributedString *mutableString = [[NSMutableAttributedString alloc] initWithString:rawString];
    [mutableString addAttribute:(NSString *)kCTFontAttributeName
                          value:(__bridge id)ctBoldFont
                          range:NSMakeRange(0, titleLength)];
    
    [mutableString addAttribute:(NSString *)kCTFontAttributeName
                          value:(__bridge id)ctFont
                          range:NSMakeRange(titleLength, rawString.length - titleLength)];
    
    CFRelease(ctFont);
    CFRelease(ctBoldFont);
    
    return mutableString;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.textLabel.textColor = [UIColor darkGrayColor];
        self.detailTextLabel.numberOfLines = 0;
    }
    return self;
}

- (void)setDisplayString:(NSAttributedString *)displayString {
    if (![_displayString isEqual:displayString]) {
        _displayString = [displayString copy];
        [self setNeedsDisplay];
    }
}

@end