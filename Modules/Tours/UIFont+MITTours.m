#import "UIFont+MITTours.h"

@implementation UIFont (MITTours)

+ (UIFont *)toursButtonTitle
{
    return [UIFont fontWithName:@"HelveticaNeue-Medium" size:20.0];
}

+ (UIFont *)toursButtonSubtitle
{
    return [UIFont fontWithName:@"HelveticaNeue" size:14];
}

+ (UIFont *)toursMapCalloutTitle
{
    return [UIFont fontWithName:@"HelveticaNeue" size:17];
}

+ (UIFont *)toursMapCalloutSubtitle
{
    return [UIFont fontWithName:@"HelveticaNeue" size:14];
}

@end
