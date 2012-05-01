#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface NSMutableAttributedString (MITAdditions)

- (void)appendString:(NSString *)string
            withFont:(UIFont*)font
           textColor:(UIColor *)color;

- (void)setFont:(UIFont *)font
     withTraits:(CTFontSymbolicTraits)traits
       forRange:(NSRange)attrRange;

- (void)setForegroundColor:(UIColor *)foregroundColor
                  forRange:(NSRange)attrRange;

- (void)setUnderline:(CTUnderlineStyle)underlineStyle
           withColor:(UIColor *)underlineColor
            forRange:(NSRange)attrRange;

- (void)setLineBreakStyle:(UILineBreakMode)lineBreakMode
            textAlignment:(UITextAlignment)textAlignment
                 forRange:(NSRange)attrRange;

@end
