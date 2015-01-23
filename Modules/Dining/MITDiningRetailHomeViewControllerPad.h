#import <UIKit/UIKit.h>

@class MITDiningMapsViewController;

@interface MITDiningRetailHomeViewControllerPad : UIViewController

@property (nonatomic, strong) NSArray *retailVenues;
@property (nonatomic, strong) MITDiningMapsViewController *mapsViewController;

- (void)refreshForNewData;

@end
