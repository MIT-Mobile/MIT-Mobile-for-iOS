#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MITMobileWebAPI.h"

@interface MapTileOverlay : NSObject <MKOverlay> {
    
    CLLocationCoordinate2D coordinate;
    MKMapRect boundingMapRect;

}

@end


@interface MapTileOverlayView : MKOverlayView {
    
}
@end
