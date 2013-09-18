#import "MITScrollingNavigationBarCell.h"
#import "UIKit+MITAdditions.h"

@implementation MITScrollingNavigationBarCell
+ (NSDictionary*)textAttributesForSelectedTitle
{
    return @{UITextAttributeFont : [UIFont boldSystemFontOfSize:[UIFont labelFontSize]]};
}

+ (NSDictionary*)textAttributesForTitle
{
    return @{UITextAttributeFont : [UIFont systemFontOfSize:[UIFont labelFontSize] - 1.]};
}

- (void)tintColorDidChange {
    self.titleLabel.textColor = self.tintColor;
}

- (UILabel*)titleLabel
{
    if (!_titleLabel) {
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

        NSDictionary *textAttributes = nil;
        if (self.isSelected) {
            textAttributes = [MITScrollingNavigationBarCell textAttributesForSelectedTitle];
        } else {
            textAttributes = [MITScrollingNavigationBarCell textAttributesForTitle];
        }

        // hardcode color on iOS 6 for now
        if ([self respondsToSelector:@selector(setTintColor:)]) {
            titleLabel.textColor = self.tintColor;
        } else {
            titleLabel.textColor = [UIColor colorWithHexString:@"a90533"];
        }
        titleLabel.font = textAttributes[UITextAttributeFont];

        [self addSubview:titleLabel];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[title]|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:@{@"title" : titleLabel}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[title]|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:@{@"title" : titleLabel}]];
        self.titleLabel = titleLabel;
    }

    return _titleLabel;
}

- (void)setSelected:(BOOL)selected
{
    [self setSelected:selected animated:YES];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected];

    NSDictionary *textAttributes = nil;
    if (selected) {
        textAttributes = [MITScrollingNavigationBarCell textAttributesForSelectedTitle];
    } else {
        textAttributes = [MITScrollingNavigationBarCell textAttributesForTitle];
    }

    [UIView animateWithDuration:(animated ? 0.4 : 0.)
                     animations:^{
                         self.titleLabel.font = textAttributes[UITextAttributeFont];
                     }];
}

@end
