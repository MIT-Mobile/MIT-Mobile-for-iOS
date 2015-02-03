#import <UIKit/UIKit.h>
#import "MITMartyResourceCell.h"

@class MITMartyResource;

extern const CGFloat kResourceCellEstimatedHeight;

@interface MITMartyResourceCell : UITableViewCell

- (void)setResource:(MITMartyResource *)resource;
- (void)setResource:(MITMartyResource *)resource order:(NSInteger)order;

+ (CGFloat)heightForResource:(MITMartyResource *)resource
           tableViewWidth:(CGFloat)width
     accessoryType:(UITableViewCellAccessoryType)accessoryType;

+ (CGFloat)heightForResource:(MITMartyResource *)resource
                    order:(NSInteger)order
           tableViewWidth:(CGFloat)width
            accessoryType:(UITableViewCellAccessoryType)accessoryType;

@end
