#import "HighlightLabel.h"

@implementation HighlightLabel
@synthesize searchString = _searchString;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.searchString = nil;
        
        self.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        self.highlightedTextColor = [UIColor redColor];
        
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
    }
    return self;
}

- (void)dealloc
{
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
    }
}

- (NSAttributedString*)highlightedString {
    if (_attributedString) {
        return [[[NSAttributedString alloc] initWithAttributedString:_attributedString] autorelease];
    }
    
    UIFont *labelFont = self.font;
    NSString *labelString = self.text;
    NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithString:labelString] autorelease];
    NSRange stringRange = [labelString rangeOfString:self.searchString
                                             options:NSCaseInsensitiveSearch];
    
    NSMutableDictionary *attrDictionary = [NSMutableDictionary dictionary];
    [attrDictionary setObject:labelFont.fontName
                       forKey:(NSString*)kCTFontNameAttribute];
    
    CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes((CFDictionaryRef)attrDictionary);
    CTFontRef ctFont = CTFontCreateWithFontDescriptor(descriptor,
                                                      labelFont.pointSize,
                                                      NULL);
    CFRelease(descriptor);
    
    if (stringRange.location == NSNotFound) {
        [attributedString addAttribute:(NSString*)kCTFontAttributeName
                                 value:(id)ctFont
                                 range:NSMakeRange(0,[labelString length])];
    } else {
        if (stringRange.location > 0) {
            [attributedString addAttribute:(NSString*)kCTFontAttributeName
                                     value:(id)ctFont
                                     range:NSMakeRange(0,stringRange.location)];
        }
        
        if ((stringRange.location + stringRange.length) < [labelString length]) {
            NSUInteger startLoc = (stringRange.location + stringRange.length);
            NSUInteger stopLoc = [labelString length] - startLoc;
            [attributedString addAttribute:(NSString*)kCTFontAttributeName
                                     value:(id)ctFont
                                     range:NSMakeRange(startLoc,stopLoc)];
        }
        CFRelease(ctFont);
        
        descriptor = CTFontDescriptorCreateWithAttributes((CFDictionaryRef)attrDictionary);
        ctFont = CTFontCreateWithFontDescriptor(descriptor,
                                                labelFont.pointSize,
                                                NULL);
        [attributedString addAttribute:(NSString*)kCTFontAttributeName
                                 value:(id)ctFont
                                 range:stringRange];
        [attributedString addAttribute:(NSString*)kCTForegroundColorAttributeName
                                 value:(id)[self.highlightedTextColor CGColor]
                                 range:stringRange];
        CFRelease(descriptor);
    }
    
    CFRelease(ctFont);
    
    _attributedString = [[NSAttributedString alloc] initWithAttributedString:attributedString];
    return [[[NSAttributedString alloc] initWithAttributedString:_attributedString] autorelease];
}

- (void)drawTextInRect:(CGRect)rect {
    if (self.searchString == nil) {
        [super drawTextInRect:rect];
    } else {
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        CGContextTranslateCTM(context, 0, rect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        CFAttributedStringRef stringRef = (CFAttributedStringRef)[self highlightedString];
        
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(stringRef);
        CGSize fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, 
                                                                       CFRangeMake(0, CFAttributedStringGetLength(stringRef)),
                                                                       NULL,
                                                                       rect.size,
                                                                       NULL);
        
        CGRect stringRect = CGRectZero;
        stringRect.size = fitSize;
        stringRect.origin.y = (rect.size.height - fitSize.height) / 2.0;
        stringRect.origin.x = rect.origin.x;
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, stringRect);
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter,
                                                    CFRangeMake(0, 0),
                                                    path,
                                                    NULL);
        CGPathRelease(path);
        CFRelease(framesetter);
        
        CTFrameDraw(frame,context);
        CFRelease(frame);
        UIGraphicsPopContext();
    }
}

@end
