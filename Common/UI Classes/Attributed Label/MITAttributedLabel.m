#import "MITAttributedLabel.h"

@interface MITAttributedLabel ()
@property (nonatomic, strong) NSMutableAttributedString *mutableAttributedString;

- (CTFontRef)createCTFontFromUIFont:(UIFont *)uiFont;

- (UIFont *)fontFromCTFont:(CTFontRef)ctFont;

- (NSDictionary *)dictionaryWithFont:(UIFont *)font
                           textStyle:(MITAttributedLabelStyle)style
                           textColor:(UIColor *)foregroundColor;
@end

@implementation MITAttributedLabel
{
    CTFramesetterRef _framesetter;
}

@synthesize mutableAttributedString = _mutableAttributedString;
@dynamic attributedString;

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.mutableAttributedString = [[[NSMutableAttributedString alloc] init] autorelease];
    }

    return self;
}

- (void)dealloc
{
    self.mutableAttributedString = nil;
    [super dealloc];
}

- (void)setString:(NSString *)string withFont:(UIFont *)font style:(MITAttributedLabelStyle)style
{
    [self setString:string
           withFont:font
              style:style
          textColor:nil];
}

- (void)setString:(NSString *)string withFont:(UIFont *)font style:(MITAttributedLabelStyle)style textColor:(UIColor *)textColor
{
    [self.mutableAttributedString deleteCharactersInRange:NSMakeRange(0, [self.mutableAttributedString length])];
    [self appendString:string
              withFont:font
                 style:style
             textColor:textColor];
}

- (void)appendString:(NSString *)string withFont:(UIFont *)font style:(MITAttributedLabelStyle)style
{
    [self appendString:string
              withFont:font
                 style:style
             textColor:nil];
}

- (void)appendString:(NSString *)string withFont:(UIFont *)font style:(MITAttributedLabelStyle)style textColor:(UIColor *)textColor
{
    if (string == nil)
    {
        return;
    }

    if (textColor == nil)
    {
        textColor = self.textColor;
    }

    if (font == nil)
    {
        font = self.font;
    }

    NSMutableDictionary *ctOptions = [NSMutableDictionary dictionaryWithDictionary:[self dictionaryWithFont:font
                                                                                                  textStyle:style
                                                                                                  textColor:textColor]];
    NSAttributedString *tempString = [[[NSAttributedString alloc] initWithString:string
                                                                      attributes:ctOptions] autorelease];
    [self.mutableAttributedString appendAttributedString:tempString];
}

#pragma mark - Overridden methods
- (void)setText:(NSString *)aText
{
    [self setString:aText
           withFont:self.font
              style:MITAttributedStyleDefault];
}

- (void)drawTextInRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0f, -1.0f);

    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)[self drawableAttributedString]);
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

    CTFrameDraw(frame, context);

    CFRelease(framesetter);
    CFRelease(frame);
}

- (CGSize)sizeThatFits:(CGSize)size
{
    NSAttributedString *attributedString = [self drawableAttributedString];
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributedString);
    CGSize fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,
                                                                  CFRangeMake(0,0),
            NULL,
                                                                  CGSizeMake(size.width, CGFLOAT_MAX),
            NULL);
    CFRelease(framesetter);

    NSLog(@"Framesetting string '%@', size: %@", [self.attributedString string], NSStringFromCGSize(fitSize));

    return CGSizeMake(size.width,
                      ceilf(fitSize.height) + 20);
}


#pragma mark - Dynamic Properties
- (NSAttributedString *)attributedString
{
    NSAttributedString *attributedString = nil;
    if (self.mutableAttributedString)
    {
        attributedString = [[NSAttributedString alloc] initWithAttributedString:self.mutableAttributedString];
    }

    return [attributedString autorelease];
}

- (void)setAttributedString:(NSAttributedString *)anAttributedString
{
    NSMutableAttributedString *mutableAttributedString = nil;

    if (anAttributedString)
    {
        mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:anAttributedString];
    }
    else
    {
        mutableAttributedString = [[NSMutableAttributedString alloc] init];
    }

    self.mutableAttributedString = [mutableAttributedString autorelease];
}

#pragma mark - Private Methods
- (NSMutableAttributedString *)drawableAttributedString
{
    NSMutableAttributedString *drawableString = [[[NSMutableAttributedString alloc] initWithAttributedString:self.mutableAttributedString] autorelease];
    CTParagraphStyleSetting styleSettings[2];

    NSLog(@"Line Break Mode: %d [%d]", self.lineBreakMode, UILineBreakModeWordWrap);
    CTLineBreakMode lineBreakMode = (CTLineBreakMode)(self.lineBreakMode);
    styleSettings[0].spec = kCTParagraphStyleSpecifierLineBreakMode;
    styleSettings[0].valueSize = sizeof(CTLineBreakMode);
    styleSettings[0].value = &lineBreakMode;

    // The range of values for the UITextAlignment does not represent
    // the full range of values for CTTextAlignment. More specifically,
    // the range of UITextAlignment values is equivalent to
    // (<CTTextAlignment> & 0x3)
    CTTextAlignment textAlignment = (CTTextAlignment)(self.textAlignment);
    styleSettings[1].spec = kCTParagraphStyleSpecifierAlignment;
    styleSettings[1].valueSize = sizeof(CTTextAlignment);
    styleSettings[1].value = &textAlignment;


    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(styleSettings, 2);
    [attributes setObject:(id)paragraphStyle
                   forKey:(id)kCTParagraphStyleAttributeName];
    CFRelease(paragraphStyle);


    if (self.isHighlighted)
    {
        UIColor *highlightColor = self.highlightedTextColor;
        [attributes setObject:(id)(highlightColor ? [highlightColor CGColor] : [[UIColor whiteColor] CGColor])
                       forKey:(id)kCTForegroundColorAttributeName];

    }

    [drawableString addAttributes:attributes
                            range:NSMakeRange(0, [drawableString length])];
    return drawableString;
}

- (NSDictionary *)dictionaryWithFont:(UIFont *)font
                           textStyle:(MITAttributedLabelStyle)style
                           textColor:(UIColor *)foregroundColor
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    CTFontRef ctFont = [self createCTFontFromUIFont:font];

    CTFontSymbolicTraits traitsValue = 0;
    CTFontSymbolicTraits traitsMask = 0;

    if (style & MITAttributedStyleBold)
    {
        traitsValue |= kCTFontBoldTrait;
        traitsMask |= kCTFontBoldTrait;
    }

    if (style & MITAttributedStyleItalic)
    {
        traitsValue |= kCTFontItalicTrait;
        traitsMask |= kCTFontItalicTrait;
    }

    if (style & MITAttributedStyleNormal)
    {
        traitsValue = 0;
        traitsMask = (CTFontSymbolicTraits)(~0);
    }

    traitsValue |= kCTFontUIOptimizedTrait;
    traitsMask |= kCTFontUIOptimizedTrait;

    CTFontRef styledFont = CTFontCreateCopyWithSymbolicTraits(ctFont,
                                                              0.0,
            NULL,
                                                              traitsValue,
                                                              traitsMask);

    if (styledFont != NULL)
    {
        ctFont = styledFont;
        CFRelease(styledFont);
        styledFont = NULL;
    }

    [dictionary setObject:(id)ctFont
                   forKey:(id)kCTFontAttributeName];

    [dictionary setObject:(id)[foregroundColor CGColor]
                   forKey:(id)kCTForegroundColorAttributeName];
    CFRelease(ctFont);


    if (style & MITAttributedStyleSingleUnderline)
    {
        [dictionary setObject:(id)[foregroundColor CGColor]
                       forKey:(id)kCTUnderlineColorAttributeName];
        [dictionary setObject:[NSNumber numberWithInteger:kCTUnderlinePatternSolid]
                       forKey:(id)kCTUnderlineStyleAttributeName];
    }

    return dictionary;
}

- (UIFont *)fontFromCTFont:(CTFontRef)ctFont
{
    CFStringRef psFontName = CTFontCopyPostScriptName(ctFont);
    NSString *ctFontName = [NSString stringWithString:(NSString *)psFontName];
    CFRelease(psFontName);

    CGFloat ptSize = CTFontGetSize(ctFont);

    return [UIFont fontWithName:ctFontName
                           size:ptSize];
}

- (CTFontRef)createCTFontFromUIFont:(UIFont *)uiFont
{
    CTFontRef ctFont = NULL;

    if (uiFont)
    {
        ctFont = CTFontCreateWithName((CFStringRef)(uiFont.fontName),
                                      uiFont.pointSize,
                NULL);
    }

    return ctFont;
}


@end
