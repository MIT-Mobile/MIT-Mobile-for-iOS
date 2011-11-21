#import <UIKit/UIKit.h>

@interface ExplanatorySectionLabel : UIView {
    UILabel *_label;
    UIImageView *_accessoryView;
    NSString *_text;
    UIFont *_font;
}

@property (nonatomic, retain) UIImageView *accessoryView;
@property (nonatomic, retain) NSString *text;

+ (CGFloat)heightWithText:(NSString *)text accessoryView:(UIImageView *)accessoryView width:(CGFloat)width;

@end
