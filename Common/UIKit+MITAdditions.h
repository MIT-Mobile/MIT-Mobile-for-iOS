#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface UIColor (MITAdditions)

+ (UIColor *)colorWithHexString:(NSString *)hexString;

@end

@interface UIImageView (MITAdditions)

+ (UIImageView *)accessoryViewWithMITType:(MITAccessoryViewType)type;
+ (UIImageView *)accessoryViewForInternalURL:(NSString *)url;

@end

@interface UIView (MITAdditions)

- (void)removeAllSubviews;

@end

@interface UITableViewCell (MITAdditions)

- (void)applyStandardFonts;
- (void)addAccessoryImage:(UIImage *)image;

@end

@interface UITableView (MITAdditions)

- (void)applyStandardColors;
- (void)applyStandardCellHeight;
+ (UIView *)groupedSectionHeaderWithTitle:(NSString *)title;
+ (UIView *)ungroupedSectionHeaderWithTitle:(NSString *)title;

@end

@interface UIActionSheet (MITAdditions)

- (void)showFromAppDelegate; // i don't like this name but can't think of a better one

@end
