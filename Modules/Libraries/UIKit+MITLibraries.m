#import "UIKit+MITLibraries.h"
#import "UIKit+MITAdditions.h"

@implementation UIFont (MITLibraries)

+ (UIFont *)librariesBookTitleStyleFont
{
    return [UIFont fontWithName:@"HelveticaNeue-Medium" size:17];
}

+ (UIFont *)librariesDetailStyleFont
{
    return [UIFont fontWithName:@"HelveticaNeue" size:14];
}

+ (UIFont *)librariesFineStyleFont
{
    return [UIFont fontWithName:@"HelveticaNeue-Medium" size:17];
}

+ (UIFont *)librariesSubtitleStyleFont
{
    return [UIFont fontWithName:@"HelveticaNeue" size:14];
}

+ (UIFont *)librariesTitleStyleFont
{
    return [UIFont fontWithName:@"HelveticaNeue" size:17];
}

+ (UIFont *)librariesAccountStatusStyleFont
{
    return [UIFont fontWithName:@"HelveticaNeue" size:24];
}

+ (UIFont *)librariesLoginStyleFont
{
    return [UIFont fontWithName:@"HelveticaNeue" size:14];
}

+ (UIFont *)librariesHeaderFont
{
    return [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
}

@end

@implementation UIColor (MITLibraries)

+ (UIColor *)librariesBackgroundColor
{
    return [UIColor colorWithRed:(244.0/255.0) green:(245.0/255.0) blue:(248.0/255.0) alpha:1];
}

+ (UIColor *)librariesFineStyleColor
{
    return [UIColor colorWithRed:179.0/255.0 green:29.0/255.0 blue:16.0/255.0 alpha:1.0];
}

+ (UIColor *)librariesDefaultSubtitleStyleColor
{
    return [UIColor colorWithWhite:0.3 alpha:1];
}

+ (UIColor *)librariesGreenSubtitleStyleColor
{
    return [UIColor colorWithRed:23.0/255.0 green:137.0/255.0 blue:27.0/255.0 alpha:1.0];
}

+ (UIColor *)librariesRedSubtitleStyleColor
{
    return [UIColor colorWithRed:179.0/255.0 green:29.0/255.0 blue:16.0/255.0 alpha:1.0];
}

+ (UIColor *)librariesAccountStatusStyleColor
{
    return [UIColor colorWithWhite:0.5 alpha:1];
}

+ (UIColor *)librariesLoginStyleColor
{
    return [UIColor mit_tintColor];
}

@end

@implementation UILabel (MITLibraries)

- (void)setLibrariesTextStyle:(MITLibrariesTextStyle)textStyle
{
    switch (textStyle) {
        case MITLibrariesTextStyleBookTitle: {
            self.font = [UIFont librariesBookTitleStyleFont];
            self.textColor = [UIColor blackColor];
            break;
        }
        case MITLibrariesTextStyleDetail: {
            self.font = [UIFont librariesDetailStyleFont];
            self.textColor = [UIColor blackColor];
            break;
        }
        case MITLibrariesTextStyleFine: {
            self.font = [UIFont librariesFineStyleFont];
            self.textColor = [UIColor librariesFineStyleColor];
            break;
        }
        case MITLibrariesTextStyleSubtitle: {
            self.font = [UIFont librariesSubtitleStyleFont];
            self.textColor = [UIColor librariesDefaultSubtitleStyleColor];
            break;
        }
        case MITLibrariesTextStyleGreenSubtitle: {
            self.font = [UIFont librariesBookTitleStyleFont];
            self.textColor = [UIColor librariesGreenSubtitleStyleColor];
            break;
        }
        case MITLibrariesTextStyleRedSubtitle: {
            self.font = [UIFont librariesBookTitleStyleFont];
            self.textColor = [UIColor librariesRedSubtitleStyleColor];
            break;
        }
        case MITLibrariesTextStyleTitle: {
            self.font = [UIFont librariesTitleStyleFont];
            self.textColor = [UIColor blackColor];
            break;
        }
        case MITLibrariesTextStyleAccountStatus: {
            self.font = [UIFont librariesAccountStatusStyleFont];
            self.textColor = [UIColor librariesAccountStatusStyleColor];
            break;
        }
        case MITLibrariesTextStyleLogIn: {
            self.font = [UIFont librariesLoginStyleFont];
            self.textColor = [UIColor librariesLoginStyleColor];
            break;
        }
    }
}

@end