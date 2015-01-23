#import <UIKit/UIKit.h>
#import "MITMapPlace.h"

@class MITMapPlace;

extern const CGFloat kMapPlaceCellEstimatedHeight;

@interface MITMapPlaceCell : UITableViewCell

- (void)setPlace:(MITMapPlace *)place;
- (void)setPlace:(MITMapPlace *)place order:(NSInteger)order;

+ (CGFloat)heightForPlace:(MITMapPlace *)place
           tableViewWidth:(CGFloat)width
     accessoryType:(UITableViewCellAccessoryType)accessoryType;

+ (CGFloat)heightForPlace:(MITMapPlace *)place
                    order:(NSInteger)order
           tableViewWidth:(CGFloat)width
            accessoryType:(UITableViewCellAccessoryType)accessoryType;

@end
