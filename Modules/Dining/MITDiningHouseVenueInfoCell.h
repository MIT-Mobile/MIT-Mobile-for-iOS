#import <UIKit/UIKit.h>

@class MITDiningHouseVenue, MITDiningHouseVenueInfoCell;

@protocol MITDiningHouseVenueInfoCellDelegate <NSObject>

- (void)infoCellDidPressInfoButton:(MITDiningHouseVenueInfoCell *)infoCell;

@end

@interface MITDiningHouseVenueInfoCell : UITableViewCell

@property (nonatomic, strong) id<MITDiningHouseVenueInfoCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;

- (void)setHouseVenue:(MITDiningHouseVenue *)venue;

+ (CGFloat)heightForHouseVenue:(MITDiningHouseVenue *)venue
                tableViewWidth:(CGFloat)width;
@end
