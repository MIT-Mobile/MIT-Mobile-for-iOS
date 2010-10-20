#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>

// http://en.wikipedia.org/wiki/Mercator_projection

/* Example usage:
 * Given location of MIT, +42.359029° latitude, -71.093577° longitude:
 *
 * CGFloat lat = 42.359029;
 * CGFloat lng = -71.093577;
 * NSInteger zoom = 18;
 * NSInteger sizeOfTile = 256;
 * CGPoint centerOfMIT = CGPointMake(lng, lat);
 * CGPoint pixelCoords = [MITProjection pixelPointForCoord:centerOfMIT zoomLevel: zoom];
 * CGPoint tileCoords = CGPointMake(floor(pixelCoords.x / sizeOfTile), floor(pixelCoords.y / sizeOfTile));
 * NSString *pathToTileContainingCenterOfMIT = [NSString stringWithFormat:@"http://maps.mit.edu/ArcGIS/rest/services/Mobile/WhereIs_MobileAll/MapServer/tile/%d/%d/%d", zoom, (NSInteger)tileCoords.y, (NSInteger)tileCoords.x];
 *
 * And to go in the other direction
 * centerOfMIT = [MITProjection coordForPixelPoint:pixelCoords zoomLevel:zoom]; // some accuracy is lost going back and forth, ±0.00001°
 */

// "http://maps.mit.edu/ArcGIS/rest/services/Mobile/WhereIs_MobileAll/MapServer/tile/" + zoom + "/" + tilePoint.y + "/" + tilePoint.x;

@interface MITProjection : NSObject {
    NSInteger tileSize;
    NSInteger maxZoomLevel;

    CGFloat *pixelsPerDegreeLongitude;
    CGFloat *radiusOfTheEarth;
    CGPoint *centerPointOfTheEarth;
    NSInteger *circumferenceOfTheEarth;
}

+ (MITProjection *)sharedProjection;

+ (CGPoint)pixelPointForCoord:(CLLocationCoordinate2D)lnglat zoomLevel:(NSInteger)zoomLevel;
+ (CLLocationCoordinate2D)coordForPixelPoint:(CGPoint)pixelPoint zoomLevel:(NSInteger)zoomLevel;

- (CGPoint)pixelPointForCoord:(CLLocationCoordinate2D)lnglat zoomLevel:(NSInteger)zoomLevel;
- (CLLocationCoordinate2D)coordForPixelPoint:(CGPoint)pixelPoint zoomLevel:(NSInteger)zoomLevel;

@end
