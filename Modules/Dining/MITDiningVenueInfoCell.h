#import <UIKit/UIKit.h>

@class MITDiningHouseVenue, MITDiningRetailVenue, MITDiningVenueInfoCell;

@protocol MITDiningHouseVenueInfoCellDelegate <NSObject>

- (void)infoCellDidPressInfoButton:(MITDiningVenueInfoCell *)infoCell;

@end

@interface MITDiningVenueInfoCell : UITableViewCell

@property (nonatomic, strong) id<MITDiningHouseVenueInfoCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;

- (void)setHouseVenue:(MITDiningHouseVenue *)venue;
- (void)setRetailVenue:(MITDiningRetailVenue *)venue;

+ (CGFloat)heightForHouseVenue:(MITDiningHouseVenue *)venue
                tableViewWidth:(CGFloat)width;
+ (CGFloat)heightForRetailVenue:(MITDiningRetailVenue *)venue
                 tableViewWidth:(CGFloat)width;

@end
