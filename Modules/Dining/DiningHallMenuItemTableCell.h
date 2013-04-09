
#import <UIKit/UIKit.h>

@interface DiningHallMenuItemTableCell : UITableViewCell

@property (nonatomic, readonly, strong) UILabel * station;
@property (nonatomic, readonly, strong) UILabel * title;
@property (nonatomic, readonly, strong) UILabel * description;
@property (nonatomic, strong) NSArray * dietaryTypes;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
+ (CGFloat) cellHeightForCellWithStation:(NSString *)station title:(NSString *) title description:(NSString *)description;

@end
