#import "UIColor+MITDatePicker.h"

@implementation UIColor (MITDatePicker)

+ (UIColor *)dp_todayColor
{
    return [UIColor colorWithRed:0.639216 green:0.121569 blue:0.203922 alpha:1.0]; // MIT Red, aka Pantone 201
}

+ (UIColor *)dp_lighterGrayTextColor
{
    return [UIColor colorWithWhite:0.4 alpha:1.0];
}

@end
