#import "HighlightLabel.h"

@implementation HighlightLabel
@synthesize searchString = _searchString;
@synthesize highlightsAllMatches = _highlightAllMatches;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.searchString = nil;
        
        self.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        self.highlightedTextColor = [UIColor colorWithRed:0.1
                                                    green:0.55
                                                     blue:0.1
                                                    alpha:1.0];
        self.highlightsAllMatches = YES;
        
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
    
    [_attributedString release], _attributedString = nil;
    
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (_attributedString) {
        [_attributedString release];
        _attributedString = nil;
        [self setNeedsDisplay];
    }
}

- (NSAttributedString*)highlightedString {
    if (_attributedString) {
        return [[[NSAttributedString alloc] initWithAttributedString:_attributedString] autorelease];
    }
    
    UIFont *labelFont = self.font;
    NSString *labelString = self.text;
    
    if (labelString == nil) {
        return [[[NSAttributedString alloc] init] autorelease];
    }
    
    NSMutableAttributedString *fullString = [[[NSMutableAttributedString alloc] initWithString:labelString] autorelease];
    

    CTFontRef ctFont = CTFontCreateWithName((CFStringRef)(self.font.fontName),
                                            labelFont.pointSize,
                                            NULL);

    [fullString addAttribute:(NSString*)kCTFontAttributeName
                       value:(id)ctFont
                       range:NSMakeRange(0,[labelString length])];

    [fullString addAttribute:(NSString*)kCTForegroundColorAttributeName
                       value:(id)[self.textColor CGColor]
                       range:NSMakeRange(0,[labelString length])];
    
    CTLineBreakMode breakMode = kCTLineBreakByTruncatingTail;
    CTParagraphStyleSetting paragraphStyle[] = {
        {
            .spec = kCTParagraphStyleSpecifierLineBreakMode,
            .valueSize = sizeof(CTLineBreakMode),
            .value = &breakMode
        }
    };
    
    [fullString addAttribute:(NSString*)kCTParagraphStyleAttributeName
                       value:(id)CTParagraphStyleCreate(paragraphStyle,1)
                       range:NSMakeRange(0,[labelString length])];
    
    
    
    NSString *searchString = self.searchString;
    if (searchString && ([searchString length] > 0)) {
        NSScanner *scanner = [NSScanner scannerWithString:labelString];
        
        while (![scanner isAtEnd]) {
            [scanner scanUpToString:searchString
                         intoString:NULL];
            
            NSString *resultString = nil;
            BOOL scanned = [scanner scanString:searchString
                                    intoString:&resultString];

            if (scanned) {
                NSRange matchRange = NSMakeRange([scanner scanLocation] - [searchString length], [searchString length]);
                NSMutableAttributedString *hlString = [[[NSMutableAttributedString alloc] initWithString:resultString] autorelease];
                
                NSRange attrRange = NSMakeRange(0, matchRange.length);
                [hlString addAttribute:(NSString*)kCTFontAttributeName
                                 value:(id)ctFont
                                 range:attrRange];
                [hlString addAttribute:(NSString*)kCTForegroundColorAttributeName
                                 value:(id)[self.highlightedTextColor CGColor]
                                 range:attrRange];
                [hlString addAttribute:(NSString*)kCTParagraphStyleAttributeName
                                 value:(id)CTParagraphStyleCreate(paragraphStyle,1)
                                 range:attrRange];
                
                [fullString replaceCharactersInRange:matchRange
                                withAttributedString:hlString];
            }
            
            if (self.highlightsAllMatches == NO) {
                [scanner setScanLocation:[labelString length]];
            }
        }
    }
    
    CFRelease(ctFont);
    
    _attributedString = [[NSAttributedString alloc] initWithAttributedString:fullString];
    return [[[NSAttributedString alloc] initWithAttributedString:fullString] autorelease];
}

- (void)drawTextInRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)[self highlightedString]);
    
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
