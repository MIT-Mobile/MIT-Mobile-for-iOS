#import <UIKit/UIKit.h>

@class MITLibrariesAvailability;

@interface MITLibrariesAvailabilityDetailCell : UITableViewCell

@property (nonatomic, strong) MITLibrariesAvailability *availability;

+ (CGFloat)heightForAvailability:(MITLibrariesAvailability *)availability tableViewWidth:(CGFloat)width;

@end
