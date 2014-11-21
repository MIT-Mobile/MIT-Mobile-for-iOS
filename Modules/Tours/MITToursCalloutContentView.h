#import <UIKit/UIKit.h>
#import "MITToursStop.h"

@interface MITToursCalloutContentView : UIControl

@property (strong, nonatomic) MITToursStop *stop;

@property (nonatomic, strong) NSString *stopType;
@property (nonatomic, strong) NSString *stopName;
@property (nonatomic) CGFloat distanceInMiles;
@property (nonatomic) BOOL shouldDisplayDistance;

- (void)configureForStop:(MITToursStop *)stop userLocation:(CLLocation *)userLocation;

@end
