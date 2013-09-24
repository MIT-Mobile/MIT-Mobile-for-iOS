
#import <UIKit/UIKit.h>

@interface DiningHallMenuItemTableCell : UITableViewCell

@property (nonatomic, readonly, strong) UILabel * station;
@property (nonatomic, readonly, strong) UILabel * title;
@property (nonatomic, readonly, strong) UILabel * subtitle;
@property (nonatomic, strong) NSArray * dietaryImagePaths;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
+ (CGFloat) cellHeightForCellWithStation:(NSString *)station title:(NSString *) title subtitle:(NSString *)subtitle;

@end
