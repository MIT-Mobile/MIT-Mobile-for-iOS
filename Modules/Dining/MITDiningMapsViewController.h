
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MITDiningMapsDisplayMode) {
    MITDiningMapsDisplayModeHouse,
    MITDiningMapsDisplayModeRetail,
    MITDiningMapsDisplayModeNotSet
};

@interface MITDiningMapsViewController : UIViewController

@property (nonatomic) MITDiningMapsDisplayMode displayMode;

@end
