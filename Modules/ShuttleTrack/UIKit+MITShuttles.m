#import "UIKit+MITShuttles.h"

@implementation UIFont (MITShuttles)

+ (UIFont *)mit_busAnnotationTitleFont
{
    return [UIFont fontWithName:@"HelveticaNeue" size:10.0];
}

@end

@implementation UIColor (MITShuttles)

+ (UIColor *)mit_busAnnotationTitleTextColor
{
    return [UIColor colorWithWhite:0.2 alpha:1.0];
}

@end
