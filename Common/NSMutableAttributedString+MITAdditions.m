#import "NSMutableAttributedString+MITAdditions.h"

static inline CTFontRef createCTFontFromUIFont(UIFont *uiFont);

static inline UIFont *UIFontForCTFont(CTFontRef ctFont);

static inline CTLineBreakMode CTLineBreakFromUILineBreak(UILineBreakMode lineBreakMode);


static inline CTFontRef createCTFontFromUIFont(UIFont *uiFont) {
    CTFontRef ctFont = NULL;

    if (uiFont)
    {
        ctFont = CTFontCreateWithName((CFStringRef)(uiFont.fontName),
                                      uiFont.pointSize,
                NULL);
    }

    return ctFont;
}

static inline UIFont *UIFontForCTFont(CTFontRef ctFont) {
    NSString *psFontName = [(NSString *)CTFontCopyName(ctFont, kCTFontPostScriptNameKey) autorelease];
    CGFloat ptSize = CTFontGetSize(ctFont);

    return [UIFont fontWithName:psFontName
                           size:ptSize];
}

static inline CTLineBreakMode CTLineBreakFromUILineBreak(UILineBreakMode lineBreakMode) {
    switch (lineBreakMode)
    {
        case UILineBreakModeWordWrap:
            return kCTLineBreakByWordWrapping;
        case UILineBreakModeCharacterWrap:
            return kCTLineBreakByCharWrapping;
        case UILineBreakModeClip:
            return kCTLineBreakByClipping;
        case UILineBreakModeHeadTruncation:
            return kCTLineBreakByTruncatingHead;
        case UILineBreakModeTailTruncation:
            return kCTLineBreakByTruncatingTail;
        case UILineBreakModeMiddleTruncation:
            return kCTLineBreakByTruncatingMiddle;
        default:
            return kCTLineBreakByWordWrapping;
    }
}

static inline CTTextAlignment CTTextAlignmentFromUITextAlignment(UITextAlignment textAlignment) {
    switch (textAlignment)
    {
        case UITextAlignmentLeft:
            return kCTLeftTextAlignment;
        case UITextAlignmentRight:
            return kCTRightTextAlignment;
        case UITextAlignmentCenter:
            return kCTCenterTextAlignment;
        default:
            return kCTLeftTextAlignment;
    }
}

@implementation NSMutableAttributedString (MITAdditions)
- (void)appendString:(NSString *)string
               withFont:(UIFont *)font
              textColor:(UIColor *)color
{
    if ([string length] > 0)
    {
        if (color == nil)
        {
            color = [UIColor blackColor];
        }

        CTFontRef ctFont = createCTFontFromUIFont(font);

        NSDictionary *attributes = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:(id)ctFont,(id)[color CGColor], nil]
                                                               forKeys:[NSArray arrayWithObjects:(const NSString*)kCTFontAttributeName, (const NSString*)kCTForegroundColorAttributeName, nil]];
        NSAttributedString *tmpString = [[[NSAttributedString alloc] initWithString:string
                                                                         attributes:attributes] autorelease];
        [self appendAttributedString:tmpString];

        if (ctFont) CFRelease(ctFont);
    }
}

- (void)setFont:(UIFont *)font
     withTraits:(CTFontSymbolicTraits)traits
       forRange:(NSRange)attrRange
{
    CTFontRef ctFont = createCTFontFromUIFont(font);
    CTFontRef styledFont = CTFontCreateCopyWithSymbolicTraits(ctFont,
                                                              0.0,
            NULL,
                                                              traits,
                                                              traits);

    if (styledFont == NULL)
    {
        ELog(@"Error: Unable to create font '%@' with traits 0x%x", [font fontName], traits);

        if (ctFont) CFRelease(ctFont);
        ctFont = styledFont;
        styledFont = NULL;
    }

    [self addAttribute:(id)ctFont
                 value:(NSString *)kCTFontAttributeName
                 range:attrRange];

    if (ctFont)
        CFRelease(ctFont);
}


- (void)setForegroundColor:(UIColor *)foregroundColor
                  forRange:(NSRange)attrRange
{
    if (foregroundColor == nil)
    {
        foregroundColor = [UIColor whiteColor];
    }

    [self addAttribute:(NSString *)kCTForegroundColorAttributeName
                 value:(id)[foregroundColor CGColor]
                 range:attrRange];
}

- (void)setUnderline:(CTUnderlineStyle)underlineStyle
           withColor:(UIColor *)underlineColor
            forRange:(NSRange)attrRange
{
    [self beginEditing];

    if (underlineColor)
    {
        [self addAttribute:(NSString *)kCTUnderlineColorAttributeName
                     value:(id)[underlineColor CGColor]
                     range:attrRange];
    }

    [self addAttribute:(NSString *)kCTUnderlineStyleAttributeName
                 value:[NSNumber numberWithInteger:underlineStyle]
                 range:attrRange];

    [self endEditing];
}


- (void)setLineBreakStyle:(UILineBreakMode)lineBreakMode
            textAlignment:(UITextAlignment)textAlignment
                 forRange:(NSRange)attrRange
{
    CTParagraphStyleSetting styleSettings[2];
    CTParagraphStyleSetting *pssPtr = NULL;

    CTLineBreakMode ctLineBreakMode = CTLineBreakFromUILineBreak(lineBreakMode);
    pssPtr = &(styleSettings[0]);
    {
        pssPtr->spec = kCTParagraphStyleSpecifierLineBreakMode;
        pssPtr->valueSize = sizeof(CTLineBreakMode);
        pssPtr->value = &ctLineBreakMode;
    }


    CTTextAlignment ctAlignment = CTTextAlignmentFromUITextAlignment(textAlignment);
    pssPtr = &(styleSettings[1]);
    {
        pssPtr->spec = kCTParagraphStyleSpecifierAlignment;
        pssPtr->valueSize = sizeof(CTTextAlignment);
        pssPtr->value = &ctAlignment;
    }

    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(styleSettings, 2);
    [self addAttribute:(NSString *)kCTParagraphStyleAttributeName
                 value:(id)paragraphStyle
                 range:attrRange];

    CFRelease(paragraphStyle);
}
@end
