#import <UIKit/UIKit.h>

@class MITMapPlace;

extern const CGFloat kMapNumberedResultCellEstimatedHeight;

@interface MITMapNumberedResultCell : UITableViewCell

- (void)setPlace:(MITMapPlace *)place order:(NSInteger)order;

@end
