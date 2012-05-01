#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

typedef enum
{
    MITAttributedStyleDefault = 0,
    MITAttributedStyleNormal = 1,
    MITAttributedStyleBold = 2,
    MITAttributedStyleItalic = 4,
    MITAttributedStyleSingleUnderline = 8
} MITAttributedLabelStyle;

@interface MITAttributedLabel : UILabel
@property (nonatomic, strong) NSAttributedString *attributedString;

- (id)initWithFrame:(CGRect)frame;
@end
