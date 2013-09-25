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

@interface UIActionSheet (MITUIAdditions)

- (void)showFromAppDelegate; // i don't like this name but can't think of a better one

@end

@interface UIAlertView (MITUIAdditions)
+ (UIAlertView*)alertViewForError:(NSError*)error withTitle:(NSString*)title alertViewDelegate:(id<UIAlertViewDelegate>)delegate;
@end

@interface UIBarButtonItem (MITUIAdditions)
+ (UIBarButtonItem*)fixedSpaceWithWidth:(CGFloat)width;
+ (UIBarButtonItem*)flexibleSpace;
@end