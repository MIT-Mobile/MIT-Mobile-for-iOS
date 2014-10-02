#import <UIKit/UIKit.h>

@class MITLibrariesAvailability;

@interface MITLibrariesHoldingLibraryHeaderCopyInfoCell : UITableViewCell

@property (nonatomic, strong) MITLibrariesAvailability *availability;

+ (CGFloat)heightForItem:(MITLibrariesAvailability *)availability tableViewWidth:(CGFloat)width;

@end
