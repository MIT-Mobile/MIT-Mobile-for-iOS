#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#pragma mark - UIKit Additon Function Prototypes
CGRect CGRectNormalizeRectInRect(CGRect subRect, CGRect parentRect);
BOOL MITCanAutorotateForOrientation(UIInterfaceOrientation desiredOrientation,UIInterfaceOrientationMask orientationMask);

NSString* NSStringFromUIImageOrientation(UIImageOrientation orientation);
BOOL MITCanAutorotateForOrientation(UIInterfaceOrientation orientation, UIInterfaceOrientationMask supportedOrientations);

#pragma mark - Category Definitions
@interface NSString (MITUIAdditions)

- (NSInteger)lengthOfLineWithFont:(UIFont *)font constrainedToSize:(CGSize)size;

@end

@interface UIColor (MITUIAdditions)
+ (UIColor*)mit_backgroundColor;
+ (UIColor *)mit_greyTextColor;
+ (UIColor *)mit_tintColor;
+ (UIColor *)mit_openGreenColor;
+ (UIColor *)mit_closedRedColor;
+ (UIColor *)mit_cellSeparatorColor;
+ (UIColor *)mit_systemTintColor;

/*!
 * Creates and returns a color object using the specified hexadecimal string.
 * Accepts strings like #0099FF, 0x0099FF, and 0099FF.
 *
 *
 *
 * Calls +[UIColor colorWithRed:green:blue:alpha:] behind the scenes.
 * @param hexString The hexadecimal string.
 * @returns Creates and returns a color object using the specified hex string.
 */
+ (UIColor *)colorWithHexString:(NSString *)hexString;

@end

@interface UIImageView (MITUIAdditions)

+ (UIImageView *)accessoryViewWithMITType:(MITAccessoryViewType)type;
+ (UIImageView *)accessoryViewForInternalURL:(NSString *)url;

@end

@interface UIView (MITUIAdditions)

- (void)removeAllSubviews;

@end

@interface UIViewController (MITUIAdditions)
- (UIView*)defaultApplicationView;
@end

@interface UIDevice (MITAdditions)
+ (BOOL)isIOS7;
- (NSString*)cpuType;
- (NSString*)sysInfoByName:(NSString*)typeSpecifier;
@end

@interface UITableViewCell (MITUIAdditions)

- (void)applyStandardFonts;
- (void)addAccessoryImage:(UIImage *)image;

@end

@interface UITableView (MITUIAdditions)

- (void)applyStandardColors;
- (void)applyStandardCellHeight;
+ (UIView *)groupedSectionHeaderWithTitle:(NSString *)title;
+ (UIView *)ungroupedSectionHeaderWithTitle:(NSString *)title;

@end

@interface UIAlertView (MITUIAdditions)
+ (UIAlertView*)alertViewForError:(NSError*)error withTitle:(NSString*)title alertViewDelegate:(id<UIAlertViewDelegate>)delegate;
@end

@interface UIBarButtonItem (MITUIAdditions)
+ (UIBarButtonItem*)fixedSpaceWithWidth:(CGFloat)width;
+ (UIBarButtonItem*)flexibleSpace;
@end

@interface UISearchBar (MITUIAdditions)
- (void)setSearchTextColor:(UIColor *)color;
@end

@interface UISearchBar (MITAdditions)
- (UITextField *)textField;
@end
