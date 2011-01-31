#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import <MapKit/MapKit.h>
#import "MITMobileWebAPI.h"

// this file interacts with an arcgis rest server
// only using the json metadata api and tiles
// so no layer/query operstions or other api.


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



#define DEGREES_PER_RADIAN 180.0 / M_PI
#define RADIANS_PER_DEGREE M_PI / 180.0

#define DEFAULT_MAP_CENTER CLLocationCoordinate2DMake(42.35913,-71.09325)
#define DEFAULT_MAP_SPAN MKCoordinateSpanMake(0.006, 0.006)

@class MapZoomLevel;
@class MITMapView;
@class MapZoomLevel;

// variation of MITProjection designed to work with MIT's ArcGIS server and MapKit
@interface MITMKProjection : NSObject <JSONLoadedDelegate> {
    
    NSMutableArray *_observers;
    
    NSArray *_mapLevels;
    
    NSMutableDictionary *_serverInfo;
    MapZoomLevel *_baseMapLevel;
    CGFloat _maximumZoomScale;
    CGFloat _minimumZoomScale;
    
    CGFloat _originX;
    CGFloat _originY;
    CGFloat _tileHeight;
    CGFloat _tileWidth;
    CGFloat _xMax;
    CGFloat _xMin;
    CGFloat _yMax;
    CGFloat _yMin;
    
    MKCoordinateRegion _defaultRegion;
    CGFloat _defaultXMin;
    CGFloat _defaultXMax;
    CGFloat _defaultYMin;
    CGFloat _defaultYMax;
    
    MKMapRect _mapRectForFullExtent;
    
    // earth measurements (for mercator projections)
    CGFloat _pixelsPerProjectedUnit;
    CGFloat _circumferenceInProjectedUnits;
    CGFloat _radiusInProjectedUnits;
    CGFloat _meridianLengthInProjectedUnits;
    BOOL _isWebMercator;
    
    long long _mapTimestamp;
}

+ (MITMKProjection *)sharedProjection;

// TODO: rename this method to something more appropriate
- (void)addObserver:(MITMapView *)observer;

- (CGFloat)maximumZoomScale;
- (CGFloat)minimumZoomScale;

- (NSArray *)mapLevels;
- (CGFloat)tileWidth;
- (CGFloat)tileHeight;

- (CGFloat)originX;
- (CGFloat)originY;

- (CLLocationCoordinate2D)northWestBoundary;
- (CLLocationCoordinate2D)southEastBoundary;

- (CGFloat)circumferenceInProjectedUnits;
- (CGFloat)meridianLengthInProjectedUnits;

- (MKCoordinateRegion)defaultRegion;
- (MKMapRect)mapRectForFullExtent;

- (MapZoomLevel *)rootMapLevel;
- (MapZoomLevel *)highestMapLevel;

- (CGFloat)pixelsPerProjectedUnit;
- (CGPoint)projectedPointForMapPoint:(MKMapPoint)mapPoint;
- (MKMapPoint)mapPointForProjectedPoint:(CGPoint)point;

- (CGPoint)projectedPointForCoord:(CLLocationCoordinate2D)coord error:(NSError **)error;
- (CLLocationCoordinate2D)coordForProjectedPoint:(CGPoint)point error:(NSError **)error;

+ (NSString *)serverInfoFilename;
+ (NSString *)mapTimestampFilename;
+ (NSString *)tileCachePath;

@end

