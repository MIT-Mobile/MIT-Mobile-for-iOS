#import <UIKit/UIKit.h>

typedef enum {
    ExplanatorySectionHeader = 0,
    ExplanatorySectionFooter,
    ExplanatorySectionCopyright
} ExplanatorySectionLabelType;

@interface ExplanatorySectionLabel : UIView

@property (nonatomic, retain) UIImageView *accessoryView;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, assign) ExplanatorySectionLabelType type;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) NSTextAlignment textAlignment;

- (id)initWithType:(ExplanatorySectionLabelType)type;

+ (CGFloat)heightWithText:(NSString *)text width:(CGFloat)width type:(ExplanatorySectionLabelType)type;
+ (CGFloat)heightWithText:(NSString *)text width:(CGFloat)width type:(ExplanatorySectionLabelType)type accessoryView:(UIImageView *)accessoryView;
+ (CGFloat)heightWithText:(NSString *)text width:(CGFloat)width type:(ExplanatorySectionLabelType)type accessoryView:(UIImageView *)accessoryView fontSize:(CGFloat)fontSize;

@end
