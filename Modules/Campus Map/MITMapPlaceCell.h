#import <UIKit/UIKit.h>

@class MITMapPlace;

extern const CGFloat kMapPlaceCellEstimatedHeight;

@interface MITMapPlaceCell : UITableViewCell

- (void)setPlace:(MITMapPlace *)place;
- (void)setPlace:(MITMapPlace *)place order:(NSInteger)order;

@end
