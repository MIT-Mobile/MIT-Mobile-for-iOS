#import <UIKit/UIKit.h>
#import "MITToursStop.h"

@protocol MITToursCalloutContentViewDelegate <NSObject>

@optional
- (void)calloutWasTappedForStop:(MITToursStop *)stop;

@end

@interface MITToursCalloutContentView : UIControl

@property (strong, nonatomic) MITToursStop *stop;
@property (strong, nonatomic) id<MITToursCalloutContentViewDelegate> delegate;

@property (nonatomic, strong) NSString *stopType;
@property (nonatomic, strong) NSString *stopName;
@property (nonatomic) CGFloat distanceInMiles;
@property (nonatomic) BOOL shouldDisplayDistance;

- (void)configureForStop:(MITToursStop *)stop userLocation:(CLLocation *)userLocation;

@end
