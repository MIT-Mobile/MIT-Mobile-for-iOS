#import <UIKit/UIKit.h>
#import "MITMartyResourceCell.h"

@class MITMartyResource;

extern const CGFloat kResourceCellEstimatedHeight;

@interface MITMartyResourceCell : UITableViewCell

- (void)setResource:(MITMartyResource *)place;
- (void)setResource:(MITMartyResource *)place order:(NSInteger)order;

+ (CGFloat)heightForResource:(MITMartyResource *)place
           tableViewWidth:(CGFloat)width
     accessoryType:(UITableViewCellAccessoryType)accessoryType;

+ (CGFloat)heightForResource:(MITMartyResource *)place
                    order:(NSInteger)order
           tableViewWidth:(CGFloat)width
            accessoryType:(UITableViewCellAccessoryType)accessoryType;

@end
