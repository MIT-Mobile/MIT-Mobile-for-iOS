#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MITLibrariesTextStyle) {
    MITLibrariesTextStyleBookTitle,
    MITLibrariesTextStyleDetail,
    MITLibrariesTextStyleFine,
    MITLibrariesTextStyleSubtitle,
    MITLibrariesTextStyleGreenSubtitle,
    MITLibrariesTextStyleRedSubtitle,
    MITLibrariesTextStyleTitle,
    MITLibrariesTextStyleAccountStatus,
    MITLibrariesTextStyleLogIn
};

@interface UIFont (MITLibraries)

+ (UIFont *)librariesBookTitleStyleFont;
+ (UIFont *)librariesDetailStyleFont;
+ (UIFont *)librariesFineStyleFont;
+ (UIFont *)librariesSubtitleStyleFont;
+ (UIFont *)librariesTitleStyleFont;
+ (UIFont *)librariesAccountStatusStyleFont;
+ (UIFont *)librariesLoginStyleFont;

@end

@interface UIColor (MITLibraries)

+ (UIColor *)librariesBackgroundColor;

+ (UIColor *)librariesFineStyleColor;
+ (UIColor *)librariesDefaultSubtitleStyleColor;
+ (UIColor *)librariesGreenSubtitleStyleColor;
+ (UIColor *)librariesRedSubtitleStyleColor;
+ (UIColor *)librariesAccountStatusStyleColor;
+ (UIColor *)librariesLoginStyleColor;

@end

@interface UILabel (MITLibraries)

- (void)setLibrariesTextStyle:(MITLibrariesTextStyle)textStyle;

@end
