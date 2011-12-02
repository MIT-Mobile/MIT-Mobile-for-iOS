#import <UIKit/UIKit.h>

typedef enum {
    ExplanatorySectionHeader = 0,
    ExplanatorySectionFooter
} ExplanatorySectionLabelType;

@interface ExplanatorySectionLabel : UIView

@property (nonatomic, retain) UIImageView *accessoryView;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, assign) ExplanatorySectionLabelType type;

+ (CGFloat)heightWithText:(NSString *)text accessoryView:(UIImageView *)accessoryView width:(CGFloat)width type:(ExplanatorySectionLabelType)type;

@end
