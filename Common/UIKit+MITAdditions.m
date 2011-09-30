#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"
#import "MIT_MobileAppDelegate.h"
#import "MITTabBarController.h"

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
        case MITAccessoryViewCalendar:
            imageName = MITImageNameCalendar;
            highlightedImageName = MITImageNameCalendarHighlight;
            break;
    }
    
    UIImage *image = [UIImage imageNamed:imageName];
    UIImage *highlightedImage = [UIImage imageNamed:highlightedImageName];
    UIImageView *accessoryView = [[UIImageView alloc] initWithImage:image highlightedImage:highlightedImage];
    return [accessoryView autorelease];
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

@implementation UITableViewCell (MITUIAdditions)

- (void)applyStandardFonts {
	self.textLabel.font = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
	self.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
    
	if (self.detailTextLabel != nil) {
		self.detailTextLabel.font = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
		self.detailTextLabel.textColor = CELL_DETAIL_FONT_COLOR;
	}
}


- (void)addAccessoryImage:(UIImage *)image {
	UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
	self.accessoryView = imageView;
	[imageView release];
}

@end

@implementation UITableView (MITUIAdditions)

- (void)applyStandardColors {
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
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 8.0, appFrame.size.width - 20.0, size.height)];
	
	label.text = title;
	label.textColor = GROUPED_SECTION_FONT_COLOR;
	label.font = font;
	label.backgroundColor = [UIColor clearColor];
	
	UIView *labelContainer = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, appFrame.size.width, GROUPED_SECTION_HEADER_HEIGHT)] autorelease];
	labelContainer.backgroundColor = [UIColor clearColor];
	
	[labelContainer addSubview:label];
	[label release];
	
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
	
	UIView *labelContainer = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, appFrame.size.width, UNGROUPED_SECTION_HEADER_HEIGHT)] autorelease];
	labelContainer.backgroundColor = UNGROUPED_SECTION_BACKGROUND_COLOR;
	
	[labelContainer addSubview:label];	
	[label release];
	
	return labelContainer;
}

@end

@implementation UIActionSheet (MITUIAdditions)
- (void)showFromAppDelegate {
    MIT_MobileAppDelegate *appDelegate = MITAppDelegate();
    [self showInView:appDelegate.rootNavigationController.view];
}
@end


