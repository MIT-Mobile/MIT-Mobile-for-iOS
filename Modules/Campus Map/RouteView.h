
#import <UIKit/UIKit.h>

@class MITMapView;

@interface RouteView : UIView {

	MITMapView* _map;
}

@property (nonatomic, assign) MITMapView* map;

@end
