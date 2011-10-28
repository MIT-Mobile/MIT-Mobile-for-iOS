#import "BookDetailTableViewCell.h"
#import <CoreText/CoreText.h>

@implementation BookDetailTableViewCell

@synthesize title, separator, subtitle, displayString;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.separator = @": ";
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)drawRect:(CGRect)rect
{
    if (!self.displayString) {
        NSString *rawString = [NSString stringWithFormat:@"%@%@%@", self.title, self.separator, self.subtitle];
        NSUInteger titleLength = 0;
        if (self.title) {
            titleLength += self.title.length;
        }
        if (self.separator) {
            titleLength += self.separator.length;
        }
        
        UIFont *font = [UIFont systemFontOfSize:15];
        CTFontRef ctFont = CTFontCreateWithName((CFStringRef)font.fontName, font.pointSize, NULL);
        
        UIFont *boldFont = [UIFont boldSystemFontOfSize:15];
        CTFontRef ctBoldFont = CTFontCreateWithName((CFStringRef)boldFont.fontName, boldFont.pointSize, NULL);

        NSMutableAttributedString *mutableString = [[[NSMutableAttributedString alloc] initWithString:rawString] autorelease];
        [mutableString addAttribute:(NSString *)kCTFontAttributeName value:(id)ctBoldFont range:NSMakeRange(0, titleLength)];
        [mutableString addAttribute:(NSString *)kCTFontAttributeName value:(id)ctFont range:NSMakeRange(titleLength, rawString.length - titleLength)];

        CFRelease(ctFont);
        CFRelease(ctBoldFont);
        
        self.displayString = [[[NSAttributedString alloc] initWithAttributedString:mutableString] autorelease];
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.displayString);
    
    // add margins to the outside rect
    CGRect innerRect = CGRectMake(10, 0, CGRectGetWidth(rect) - 20, CGRectGetHeight(rect));
    
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

- (void)dealloc
{
    self.title = nil;
    self.subtitle = nil;
    self.separator = nil;
    self.displayString = nil;
    [super dealloc];
}

@end


@implementation LibrariesBorderedTableViewCell

@synthesize borderColor, fillColor, cellPosition;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.borderColor = [UIColor colorWithWhite:0.5 alpha:1];
        self.fillColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor clearColor];
        self.cellPosition = 0;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGColorRef currentColor = [self.borderColor CGColor];
    CGColorSpaceRef colorSpace = CGColorGetColorSpace(currentColor);
    CGContextSetStrokeColorSpace(context, colorSpace);
    const CGFloat *components = CGColorGetComponents(currentColor);
    CGContextSetStrokeColor(context, components);
    
    currentColor = [self.fillColor CGColor];
    colorSpace = CGColorGetColorSpace(currentColor);
    CGContextSetFillColorSpace(context, colorSpace);
    components = CGColorGetComponents(currentColor);
    CGContextSetFillColor(context, components);

    // we don't know the actual values of left and right margins,
    // which depend on the, width of the table view
    // so we do the fill manually in addition to the stroke
    CGFloat minx = CGRectGetMinX(rect) + 10;
    CGFloat midx = CGRectGetMidX(rect);
    CGFloat maxx = CGRectGetMaxX(rect) - 10;
    CGFloat miny = CGRectGetMinY(rect);
    CGFloat midy = CGRectGetMidY(rect);
    CGFloat maxy = CGRectGetMaxY(rect);
    CGFloat radius = 10;

    for (NSInteger i = 0; i < 2; i++) {
        // start from left and move clockwise
        CGContextMoveToPoint(context, minx, midy);
        if (self.cellPosition & TableViewCellPositionFirst) {
            CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
            CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
        } else {
            CGContextAddLineToPoint(context, minx, miny);
            CGContextAddLineToPoint(context, maxx, miny);
            CGContextAddLineToPoint(context, maxx, midy);
        }
        
        if (self.cellPosition & TableViewCellPositionLast) {
            CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
            CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
        } else {
            CGContextAddLineToPoint(context, maxx, maxy);
            CGContextAddLineToPoint(context, midx, maxy);
            CGContextAddLineToPoint(context, minx, maxy);
            CGContextAddLineToPoint(context, minx, midy);
        }
        
        CGContextClosePath(context);

        if (i == 0) {
            CGContextFillPath(context);
        } else {
            CGContextStrokePath(context);
        }
    }
}

- (void)dealloc
{
    self.borderColor = nil;
    self.fillColor = nil;
    [super dealloc];
}

@end










