#import "UIKit+MITAdditions.h"


@implementation UIColor (MITAdditions)

// snagged from http://arstechnica.com/apple/guides/2009/02/iphone-development-accessing-uicolor-components.ars
// color must be either of the format @"0099FF" or @"#0099FF" or @"0x0099FF"
+ (UIColor *)colorWithHexString:(NSString *)hexString  
{  
    NSString *cString = [[hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 - 8 characters
    if ([cString length] < 6) return nil;
    
    // strip 0X and # if they appear
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"]) cString = [cString substringFromIndex:1];
    
    if ([cString length] != 6) return nil;
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}  

@end

@implementation UIImageView (MITAdditions)

+ (UIImageView *)accessoryViewWithMITType:(MITAccessoryViewType)type {
    NSString *imageName = nil;
    NSString *highlightedImageName = nil;

    switch (type) {
        case MITAccessoryViewEmail:
            imageName = MITImageNameEmail;
            highlightedImageName = MITImageNameEmailHighlight;
            break;
        case MITAccessoryViewMap:
            imageName = MITImageNameMap;
            highlightedImageName = MITImageNameMapHighlight;
            break;
        case MITAccessoryViewPeople:
            imageName = MITImageNamePeople;
            highlightedImageName = MITImageNamePeopleHighlight;
            break;
        case MITAccessoryViewPhone:
            imageName = MITImageNamePhone;
            highlightedImageName = MITImageNamePhoneHighlight;
            break;
        case MITAccessoryViewExternal:
            imageName = MITImageNameExternal;
            highlightedImageName = MITImageNameExternalHighlight;
            break;
		case MITAccessoryViewEmergency:
			imageName = MITImageNameEmergency;
			highlightedImageName = MITImageNameEmergencyHighlight;
			break;
        case MITAccessoryViewSecure:
            imageName = MITImageNameSecure;
            highlightedImageName = MITImageNameSecureHighlight;
            break;
    }
    
    UIImage *image = [UIImage imageNamed:imageName];
    UIImage *highlightedImage = [UIImage imageNamed:highlightedImageName];
    UIImageView *accessoryView = [[UIImageView alloc] initWithImage:image highlightedImage:highlightedImage];
    return [accessoryView autorelease];
}

@end