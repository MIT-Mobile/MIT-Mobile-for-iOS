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
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        self.backgroundView.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setDisplayString:(NSAttributedString *)displayString {
    if (![_displayString isEqual:displayString]) {
        _displayString = [displayString copy];
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.displayString);
    
    // add margins to the outside rect
    CGRect innerRect = CGRectMake(BOOK_DETAIL_CELL_MARGIN, 0,
                                  CGRectGetWidth(rect) - BOOK_DETAIL_CELL_MARGIN * 2,
                                  CGRectGetHeight(rect));
    
    CGSize fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, 
                                                                  CFRangeMake(0, 0),
                                                                  NULL,
                                                                  innerRect.size,
                                                                  NULL);
    
    CGRect stringRect = CGRectZero;
    stringRect.size.height = ceilf(fitSize.height);
    stringRect.size.width = ceilf(fitSize.width);
    stringRect.origin.y = ceilf((innerRect.size.height - fitSize.height) / 2.0);
    stringRect.origin.x = innerRect.origin.x;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, stringRect);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter,
                                                CFRangeMake(0, 0),
                                                path,
                                                NULL);
    CGPathRelease(path);
    
    CTFrameDraw(frame,context);
    
    CFRelease(framesetter);
    CFRelease(frame);
}
@end