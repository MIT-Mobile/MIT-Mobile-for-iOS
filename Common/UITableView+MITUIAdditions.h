#import <UIKit/UIKit.h>


@interface UITableView (MITUIAdditions)

- (void)applyStandardColors;

- (void)applyStandardCellHeight;

+ (UIView *)groupedSectionHeaderWithTitle:(NSString *)title;
+ (UIView *)ungroupedSectionHeaderWithTitle:(NSString *)title;

@end
