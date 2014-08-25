#import <UIKit/UIKit.h>

@class MITDiningHouseVenue, MITDiningRetailVenue;

@interface MITDiningVenueCell : UITableViewCell

- (void)setHouseVenue:(MITDiningHouseVenue *)venue withNumberPrefix:(NSString *)numberPrefix;

+ (CGFloat)heightForHouseVenue:(MITDiningHouseVenue *)venue
                tableViewWidth:(CGFloat)width;

@end
