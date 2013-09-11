#import "MITScrollingNavigationBarCell.h"

@implementation MITScrollingNavigationBarCell
+ (NSDictionary*)textAttributesForSelectedTitle
{
    return @{UITextAttributeFont : [UIFont boldSystemFontOfSize:[UIFont labelFontSize]],
             UITextAttributeTextColor : [UIColor whiteColor]};
}

+ (NSDictionary*)textAttributesForTitle
{
    return @{UITextAttributeFont : [UIFont systemFontOfSize:[UIFont labelFontSize] - 1.],
             UITextAttributeTextColor : [UIColor whiteColor]};
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

        titleLabel.textColor = textAttributes[UITextAttributeTextColor];
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
                         self.titleLabel.textColor = textAttributes[UITextAttributeTextColor];
                         self.titleLabel.font = textAttributes[UITextAttributeFont];
                     }];
}

@end
