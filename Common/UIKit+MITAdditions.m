#include <sys/sysctl.h>
#include <mach/machine.h>

#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"
#import "MIT_MobileAppDelegate.h"

inline CGRect CGRectNormalizeRectInRect(CGRect subRect, CGRect parentRect)
{
    CGRect normalizedRect = CGRectMake(subRect.origin.x / CGRectGetMaxX(parentRect),
                                       subRect.origin.y / CGRectGetMaxY(parentRect),
                                       subRect.size.width / CGRectGetWidth(parentRect),
                                       subRect.size.height / CGRectGetHeight(parentRect));
    
    return normalizedRect;
}

inline BOOL MITCanAutorotateForOrientation(UIInterfaceOrientation desiredOrientation,UIInterfaceOrientationMask orientationMask)
{
    return ((1 << desiredOrientation) & orientationMask) != 0;
}

NSString* NSStringFromUIImageOrientation(UIImageOrientation orientation)
{
    switch (orientation) {
        case UIImageOrientationDown:
            return [NSString stringWithFormat:@"%@ [%d]", @"UIImageOrientationDown", UIImageOrientationDown];
        case UIImageOrientationDownMirrored:
            return [NSString stringWithFormat:@"%@ [%d]", @"UIImageOrientationDownMirrored", UIImageOrientationDownMirrored];
        case UIImageOrientationLeft:
            return [NSString stringWithFormat:@"%@ [%d]", @"UIImageOrientationLeft", UIImageOrientationLeft];
        case UIImageOrientationLeftMirrored:
            return [NSString stringWithFormat:@"%@ [%d]", @"UIImageOrientationLeftMirrored", UIImageOrientationLeftMirrored];
        case UIImageOrientationUp:
            return [NSString stringWithFormat:@"%@ [%d]", @"UIImageOrientationUp", UIImageOrientationUp];
        case UIImageOrientationUpMirrored:
            return [NSString stringWithFormat:@"%@ [%d]", @"UIImageOrientationUpMirrored", UIImageOrientationUpMirrored];
        case UIImageOrientationRight:
            return [NSString stringWithFormat:@"%@ [%d]", @"UIImageOrientationRight", UIImageOrientationRight];
        case UIImageOrientationRightMirrored:
            return [NSString stringWithFormat:@"%@ [%d]", @"UIImageOrientationRightMirrored", UIImageOrientationRightMirrored];
    }
}


@implementation NSString (MITUIAdditions)

- (NSInteger)lengthOfLineWithFont:(UIFont *)font constrainedToSize:(CGSize)size {
    NSMutableString *mutableString = [NSMutableString string];
    NSArray *lines = [self componentsSeparatedByString:@"\n"];
    if (lines.count > 0) {
        NSString *line = [lines objectAtIndex:0];
        NSArray *words = [line componentsSeparatedByString:@" "];
        NSInteger count = words.count;
        if (count > 0) {
            NSInteger index = 0;
            [mutableString appendString:[words objectAtIndex:index]];
            CGSize fullSize = [mutableString sizeWithFont:font];
            index++;
            while (index < count && fullSize.width < size.width) {
                [mutableString appendString:[NSString stringWithFormat:@" %@", [words objectAtIndex:index]]];
                fullSize = [mutableString sizeWithFont:font];
                index++;
            }
        }
    }
    return [mutableString length];
}

@end

@implementation UIColor (MITUIAdditions)
+ (UIColor* )mit_backgroundColor
{
    return [UIColor colorWithHexString:@"d7dae0"];
}

+ (UIColor *)mit_greyTextColor
{
    return [UIColor colorWithWhite:0.3 alpha:1.0];
}

+ (UIColor *)mit_tintColor
{
    return [UIColor colorWithHexString:@"a31f34"]; // MIT Red, aka Pantone 201
}

+ (UIColor *)mit_openGreenColor
{
    return [UIColor colorWithHexString:@"0abf00"];
}

+ (UIColor *)mit_closedRedColor
{
    return [UIColor colorWithHexString:@"e52200"];
}

+ (UIColor *)mit_cellSeparatorColor
{
    return [UIColor colorWithRed:227.0/255.0 green:227.0/255.0 blue:229.0/255.0 alpha:1.0];
}

+ (UIColor *)mit_navBarColor
{
    return [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0];
}

+ (UIColor *)mit_systemTintColor
{
    return [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
}

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

@implementation UIImageView (MITUIAdditions)

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
            imageName = MITImageActionExternal;
            highlightedImageName = MITImageActionExternalHighlight;
            break;
		case MITAccessoryViewEmergency:
			imageName = MITImageNameEmergency;
			highlightedImageName = MITImageNameEmergencyHighlight;
			break;
        case MITAccessoryViewSecure:
            imageName = MITImageNameSecure;
            highlightedImageName = MITImageNameSecureHighlight;
            break;
        case MITAccessoryViewCalendar:
            imageName = MITImageNameCalendar;
            highlightedImageName = MITImageNameCalendarHighlight;
            break;
    }
    
    UIImage *image = [UIImage imageNamed:imageName];
    UIImage *highlightedImage = [UIImage imageNamed:highlightedImageName];
    UIImageView *accessoryView = [[UIImageView alloc] initWithImage:image highlightedImage:highlightedImage];
    return accessoryView;
}

+ (UIImageView *)accessoryViewForInternalURL:(NSString *)url {
	// we should really check for whether this url fits our internal scheme
	NSArray *pathComponents = [url pathComponents];
	if (pathComponents.count > 1) {
		NSString *localPath = [pathComponents objectAtIndex:1];
		if ([localPath isEqualToString:CampusMapTag]) {
			return [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
		} else if ([localPath isEqualToString:DirectoryTag]) {
			return [UIImageView accessoryViewWithMITType:MITAccessoryViewPeople];
		} else if ([localPath isEqualToString:EmergencyTag]) {
			return [UIImageView accessoryViewWithMITType:MITAccessoryViewEmergency];
		}
	}
	return nil;
}

@end

@implementation UIView (MITUIAdditions)

- (void)removeAllSubviews {
    for (UIView *aView in self.subviews) {
        [aView removeFromSuperview];
    }
}

@end

@implementation UIViewController (MITUIAdditions)
- (UIView*)defaultApplicationView {
    CGRect mainFrame = [[UIScreen mainScreen] applicationFrame];
    
    UIView *mainView = [[UIView alloc] initWithFrame:mainFrame];
    mainView.autoresizesSubviews = YES;
    mainView.backgroundColor = [UIColor mit_backgroundColor];
    
    return mainView;
}

@end



@implementation UIDevice (MITAdditions)
+ (BOOL)isIOS7
{
    NSString *reqSysVer = @"7.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];

    return ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
}

- (NSString*)sysInfoByName:(NSString*)typeSpecifier
{
    const char *typeString = [typeSpecifier UTF8String];
    size_t size = 0;
    int status = sysctlbyname(typeString, NULL, &size, NULL, 0);

    if (status) {
        DDLogError(@"sysctl '%@' failed: %s", typeSpecifier, strerror(status));
        return nil;
    }

    char *result = malloc(size);
    memset(result, 0, size);
    status = sysctlbyname(typeString, result, &size, NULL, 0);
    if (status) {
        DDLogError(@"sysctl '%@' failed: %s", typeSpecifier, (const char*)strerror(status));
        free(result);
        return nil;
    }

    NSString *resultString = [NSString stringWithCString:result
                                                encoding:NSUTF8StringEncoding];
    free(result);
    return resultString;
}

- (NSString*)cpuType
{
    cpu_type_t cpuType = CPU_TYPE_ANY;
    cpu_subtype_t cpuSubtype = CPU_SUBTYPE_MULTIPLE;

    size_t size = sizeof(cpu_type_t);
    sysctlbyname("hw.cputype", &cpuType, &size, NULL, 0);

    size = sizeof(cpu_subtype_t);
    sysctlbyname("hw.cpusubtype", &cpuSubtype, &size, NULL, 0);
    if (cpuType == CPU_TYPE_ARM) {
        NSMutableString *cpuString = [NSMutableString stringWithString:@"armv"];
        switch (cpuSubtype)
        {
            case CPU_SUBTYPE_ARM_V4T:
                [cpuString appendString:@"4t"];
                break;
            case CPU_SUBTYPE_ARM_V5TEJ:
                [cpuString appendString:@"5tej"];
                break;
            case CPU_SUBTYPE_ARM_V6:
                [cpuString appendString:@"6"];
                break;
            case CPU_SUBTYPE_ARM_V6M:
                [cpuString appendString:@"6m"];
                break;
            case CPU_SUBTYPE_ARM_V7:
                [cpuString appendString:@"7"];
                break;
            case CPU_SUBTYPE_ARM_V7EM:
                [cpuString appendString:@"7s"];
                break;
            case CPU_SUBTYPE_ARM_V7F:
                [cpuString appendString:@"7f"];
                break;
            case CPU_SUBTYPE_ARM_V7K:
                [cpuString appendString:@"7k"];
                break;
            case CPU_SUBTYPE_ARM_V7M:
                [cpuString appendString:@"7s"];
                break;
            case CPU_SUBTYPE_ARM_V7S:
                [cpuString appendString:@"7s"];
                break;
        }

        return cpuString;
    } else if (cpuType == CPU_TYPE_X86_64) {
        return @"x86_64";
    } else if (cpuType == CPU_TYPE_X86) {
        return @"i386";
    } else {
        return @"Unknown";
    }
}
@end

@implementation UITableViewCell (MITUIAdditions)

- (void)applyStandardFonts {
	self.textLabel.font = [UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE];
	self.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
    
	if (self.detailTextLabel != nil) {
		self.detailTextLabel.font = [UIFont systemFontOfSize:CELL_DETAIL_FONT_SIZE];
		self.detailTextLabel.textColor = CELL_DETAIL_FONT_COLOR;
	}
}


- (void)addAccessoryImage:(UIImage *)image {
	UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
	self.accessoryView = imageView;
}

@end

@implementation UITableView (MITUIAdditions)

- (void)applyStandardColors {
    self.backgroundView = nil;
    self.opaque = NO;
	self.backgroundColor = [UIColor clearColor]; // allows background to show through
	self.separatorColor = TABLE_SEPARATOR_COLOR;
}

- (void)applyStandardCellHeight {
	self.rowHeight = CELL_TWO_LINE_HEIGHT;
}

+ (UIView *)groupedSectionHeaderWithTitle:(NSString *)title {
	UIFont *font = [UIFont boldSystemFontOfSize:STANDARD_CONTENT_FONT_SIZE];
	CGSize size = [title sizeWithFont:font];
	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(19.0, 7.0, appFrame.size.width - 19.0, size.height)];
	
	label.text = title;
	label.textColor = GROUPED_SECTION_FONT_COLOR;
	label.font = font;
	label.backgroundColor = [UIColor clearColor];
	
	UIView *labelContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, appFrame.size.width, GROUPED_SECTION_HEADER_HEIGHT)];
	labelContainer.backgroundColor = [UIColor clearColor];
	
	[labelContainer addSubview:label];
	
	return labelContainer;
}

+ (UIView *)ungroupedSectionHeaderWithTitle:(NSString *)title {
	UIFont *font = [UIFont boldSystemFontOfSize:STANDARD_CONTENT_FONT_SIZE];
	CGSize size = [title sizeWithFont:font];
	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, appFrame.size.width - 20.0, size.height)];
	
	label.text = title;
	label.textColor = UNGROUPED_SECTION_FONT_COLOR;
	label.font = font;
	label.backgroundColor = [UIColor clearColor];
	
	UIView *labelContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, appFrame.size.width, UNGROUPED_SECTION_HEADER_HEIGHT)];
	labelContainer.backgroundColor = UNGROUPED_SECTION_BACKGROUND_COLOR;
	
	[labelContainer addSubview:label];
	
	return labelContainer;
}

@end


#define JSON_ERROR_CODE -2
@implementation UIAlertView (MITUIAdditions)
+ (UIAlertView*)alertViewForError:(NSError*)error withTitle:(NSString*)title alertViewDelegate:(id<UIAlertViewDelegate>)delegate
{
	// Generic message
	NSString *message = @"Connection Failure. Please try again later.";
    
	// if the error can be classifed we will use a more specific error message
	if(error) {
		if ([[error domain] isEqualToString:@"NSURLErrorDomain"] && ([error code] == NSURLErrorTimedOut)) {
			message = @"Connection Timed Out. Please try again later.";
		} else if ([[error domain] isEqualToString:@"MITMobileWebAPI"] && ([error code] == JSON_ERROR_CODE)) {
			message = @"Server Failure. Please try again later.";
		}
	}
    
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
														message:message
													   delegate:delegate
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
    
    return alertView;
}
@end


@implementation UIBarButtonItem (MITUIAdditions)
+ (UIBarButtonItem*)fixedSpaceWithWidth:(CGFloat)width
{
    UIBarButtonItem *item = [[self alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    item.width = width;

    return item;
}

+ (UIBarButtonItem*)flexibleSpace
{
    return [[self alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}
@end

@implementation UISearchBar (MITUIAdditions)

// have to iterate through the subviews to change text color. Using appearance proxy doesn't
// work unless it's changed once at searchBar creation time.
// http://stackoverflow.com/questions/19048766/uisearchbar-text-color-change-in-ios-7
- (void)setSearchTextColor:(UIColor *)color
{
    for (UIView *subView in self.subviews)
    {
        for (UIView *secondLevelSubview in subView.subviews)
        {
            if ([secondLevelSubview isKindOfClass:[UITextField class]])
            {
                UITextField *searchBarTextField = (UITextField *)secondLevelSubview;
                [searchBarTextField setTextColor:color];
                
                break;
            }
        }
    }
}
@end

@implementation UISearchBar (MITAdditions)
- (UITextField *)textField
{
    for (UIView *subview in self.subviews) {
        for (UIView *secondLevelSubview in subview.subviews){
            if ([secondLevelSubview isKindOfClass:[UITextField class]]) {
                return (UITextField *)secondLevelSubview;
            }
        }
    }
    return nil;
}
@end
