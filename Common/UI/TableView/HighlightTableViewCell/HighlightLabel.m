#import "HighlightLabel.h"

@interface HighlightLabel ()
@property (nonatomic,retain) NSAttributedString *attributedString;
@end

@implementation HighlightLabel
@synthesize matchedTextColor = _matchedTextColor;
@synthesize searchString = _searchString;
@synthesize highlightAllMatches = _highlightAllMatches;
@synthesize attributedString = _attributedString;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.searchString = nil;
        
        self.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        self.matchedTextColor = [UIColor colorWithRed:0.643
                                                green:0.000
                                                 blue:0.114
                                                alpha:1.0];
        self.highlightedTextColor = [UIColor whiteColor];
        self.highlightAllMatches = YES;
        
        [self addObserver:self
               forKeyPath:@"font"
                  options:0
                  context:NULL];
        [self addObserver:self
               forKeyPath:@"text"
                  options:0
                  context:NULL];
        [self addObserver:self
               forKeyPath:@"highlightedTextColor"
                  options:0
                  context:NULL];
        [self addObserver:self
               forKeyPath:@"searchString"
                  options:0
                  context:NULL];
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self
              forKeyPath:@"font"];
    [self removeObserver:self
              forKeyPath:@"highlightedTextColor"];
    [self removeObserver:self
              forKeyPath:@"text"];
    [self removeObserver:self
              forKeyPath:@"searchString"];
    
    self.attributedString = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (self.attributedString) {
        self.attributedString = nil;
        [self setNeedsDisplay];
    }
}

- (NSAttributedString*)attributedString {
    if (_attributedString) {
        return _attributedString;
    }
    
    UIFont *labelFont = self.font;
    NSString *labelString = self.text;
    NSString *searchString = self.searchString;
    
    if (labelString == nil) {
        return [[NSAttributedString alloc] init];
    }
    
    NSMutableAttributedString *fullString = [[NSMutableAttributedString alloc] initWithString:labelString];
    
    CTFontRef ctFont = CTFontCreateWithName((CFStringRef)(self.font.fontName),
                                            labelFont.pointSize,
                                            NULL);

    CTLineBreakMode breakMode = (CTLineBreakMode)(self.lineBreakMode);
    CTParagraphStyleSetting styleSettings = 
        {
            .spec = kCTParagraphStyleSpecifierLineBreakMode,
            .valueSize = sizeof(CTLineBreakMode),
            .value = &breakMode
        };
    
    UIColor *textColor = (self.isHighlighted ? self.highlightedTextColor : self.textColor);
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(&styleSettings, 1);
    NSDictionary *attrs = @{NSFontAttributeName : (__bridge id)ctFont,
                            NSForegroundColorAttributeName : textColor,
                            NSParagraphStyleAttributeName : (__bridge id)paragraphStyle};
    CFRelease(paragraphStyle);
    [fullString setAttributes:attrs
                        range:NSMakeRange(0, [fullString length])];

    
    if (searchString && ([searchString length] > 0) && (self.isHighlighted == NO)) {
        NSError *error = NULL;
        NSString *pattern = [NSRegularExpression escapedPatternForString:searchString];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        
        [regex enumerateMatchesInString:labelString 
                                options:0
                                  range:NSMakeRange(0, [labelString length]) 
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSRange matchRange = [result range];
            if (matchRange.location != NSNotFound) {
                [fullString addAttribute:(NSString *)kCTForegroundColorAttributeName 
                                   value:(id)[self.matchedTextColor CGColor] 
                                   range:matchRange];
                if (self.highlightAllMatches == NO) {
                    *stop = YES;
                }
            }
        }];
    }
    
    CFRelease(ctFont);
    
    self.attributedString = [[NSAttributedString alloc] initWithAttributedString:fullString];
    return _attributedString;
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (self.highlighted != highlighted)
    {
        self.attributedString = nil;
    }
    
    [super setHighlighted:highlighted];
}

- (void)drawTextInRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithAttributedString:self.attributedString];
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrString);
    
    CGSize fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, 
                                                                   CFRangeMake(0, 0),
                                                                   NULL,
                                                                   rect.size,
                                                                   NULL);

    CGRect stringRect = CGRectZero;
    stringRect.size.height = ceilf(fitSize.height);
    stringRect.size.width = ceilf(fitSize.width);
    stringRect.origin.y = ceilf((rect.size.height - fitSize.height) / 2.0);
    stringRect.origin.x = rect.origin.x;
    
    
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
