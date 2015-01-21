#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MITActionRowType) {
    MITActionRowTypeSpeaker,
    MITActionRowTypeTime,
    MITActionRowTypeLocation,
    MITActionRowTypePhone,
    MITActionRowTypeDescription,
    MITActionRowTypeWebsite,
    MITActionRowTypeOpenTo,
    MITActionRowTypeCost,
    MITActionRowTypeSponsors,
    MITActionRowTypeContact
};

@interface MITActionCell : UITableViewCell

+ (UINib *)actionCellNib;
+ (NSString *)actionCellNibName;
+ (NSString *)actionCellIdentifier;

- (void)setTitle:(NSString *)title;
- (void)setDetailText:(NSString *)detailText;
- (void)setupCellOfType:(MITActionRowType)type withDetailText:(NSString *)detailText;



@end
