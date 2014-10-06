#import <UIKit/UIKit.h>

@interface MITDiningFiltersCell : UITableViewCell

- (void)setFilters:(NSSet *)filters;
+ (CGFloat)heightForFilters:(NSSet *)filters
             tableViewWidth:(CGFloat)width;
@end
