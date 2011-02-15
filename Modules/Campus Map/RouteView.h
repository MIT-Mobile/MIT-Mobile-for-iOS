
#import <UIKit/UIKit.h>

@class MITMapView;

@interface RouteView : UIView {
	__weak MITMapView* _map;
}

@property (nonatomic, assign) MITMapView* map;

@end
