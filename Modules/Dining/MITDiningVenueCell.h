#import <UIKit/UIKit.h>

@class MITDiningHouseVenue, MITDiningRetailVenue;

@interface MITDiningVenueCell : UITableViewCell

- (void)setVenue:(id)venue withNumberPrefix:(NSString *)numberPrefix;

+ (CGFloat)heightForHouseVenue:(MITDiningHouseVenue *)venue
                tableViewWidth:(CGFloat)width;

+ (CGFloat)heightForRetailVenue:(MITDiningRetailVenue *)venue
               withNumberPrefix:(NSString *)numberPrefix
                 tableViewWidth:(CGFloat)width;
@end
