#import <Foundation/Foundation.h>

@class MGSMapView;

@protocol MGSMapViewDelegate <NSObject>
- (void)didFinishLoadingMapView:(MGSMapView*)mapView;
@end
