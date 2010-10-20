#import "MITProjection.h"

#define TILE_SIZE 256 // Pixel dimensions of map tiles. Square tiles assumed.
#define MAX_ZOOM_LEVEL 20 // Google Maps style levels of zoom. Powers of two. Circumference of the world == TILE_SIZE * (2 ** zoom)

@implementation MITProjection

#pragma mark -
#pragma mark Singleton Boilerplate

static MITProjection *sharedProjection = nil;

+ (MITProjection *)sharedProjection
{
	if (sharedProjection == nil) {
		sharedProjection = [[MITProjection alloc] init];
	}
	
	return sharedProjection;
}


#pragma mark -
#pragma mark Initialization

- (id) init
{
    self = [super init];
    if (self != nil) {
        NSInteger err = 0;
        tileSize = TILE_SIZE;
        maxZoomLevel = MAX_ZOOM_LEVEL;
        if (!err) {
            pixelsPerDegreeLongitude = malloc(sizeof(CGFloat) * (maxZoomLevel + 1));
            if (pixelsPerDegreeLongitude == NULL) { err = ENOMEM; }
        }
        if (!err) {
            radiusOfTheEarth = malloc(sizeof(CGFloat) * (maxZoomLevel + 1));
            if (radiusOfTheEarth == NULL) { err = ENOMEM; }
        }
        if (!err) {
            centerPointOfTheEarth = malloc(sizeof(CGPoint) * (maxZoomLevel + 1));
            if (centerPointOfTheEarth == NULL) { err = ENOMEM; }
        }
        if (!err) {
            circumferenceOfTheEarth = malloc(sizeof(NSInteger) * (maxZoomLevel + 1));
            if (circumferenceOfTheEarth == NULL) { err = ENOMEM; }
        }
        // precalculate a few expressions for each zoom level
        if (!err) {
            // d == zoom level (0 - 20)
            // c == circumference of the Earth at this zoom level
            for (NSInteger c = tileSize, d = 0; d <= maxZoomLevel; d++) {
                CGFloat halfC = c / 2.0;
                pixelsPerDegreeLongitude[d] = c / 360.0;
                radiusOfTheEarth[d] = c / (2 * M_PI);
                centerPointOfTheEarth[d] = CGPointMake(halfC, halfC);
                circumferenceOfTheEarth[d] = c;
                c *= 2;
            }
        } else {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    if (pixelsPerDegreeLongitude) {
        free(pixelsPerDegreeLongitude);
        pixelsPerDegreeLongitude = NULL;
    }
    if (radiusOfTheEarth) {
        free(radiusOfTheEarth);
        radiusOfTheEarth = NULL;
    }
    if (centerPointOfTheEarth) {
        free(centerPointOfTheEarth);
        centerPointOfTheEarth = NULL;
    }
    if (circumferenceOfTheEarth) {
        free(circumferenceOfTheEarth);
        circumferenceOfTheEarth = NULL;
    }
    [super dealloc];
}

#pragma mark -
#pragma mark Projections

+ (CGPoint)pixelPointForCoord:(CLLocationCoordinate2D)lnglat zoomLevel:(NSInteger)zoomLevel {
    return [[MITProjection sharedProjection] pixelPointForCoord:lnglat zoomLevel:zoomLevel];
}

+ (CLLocationCoordinate2D)coordForPixelPoint:(CGPoint)pixelPoint zoomLevel:(NSInteger)zoomLevel {
    return [[MITProjection sharedProjection] coordForPixelPoint:pixelPoint zoomLevel:zoomLevel];
}

- (CGPoint)pixelPointForCoord:(CLLocationCoordinate2D)lnglat zoomLevel:(NSInteger)zoomLevel {
    CGFloat x = round(centerPointOfTheEarth[zoomLevel].x + (lnglat.longitude * pixelsPerDegreeLongitude[zoomLevel]));
    CGFloat a = MIN(MAX(sin(lnglat.latitude * M_PI / 180.0), -0.9999), 0.9999); // used twice, calculate once
    CGFloat y = round(centerPointOfTheEarth[zoomLevel].y + (0.5 * log((1 + a) / (1 - a))) * -radiusOfTheEarth[zoomLevel]);
    return CGPointMake(x, y);
}

- (CLLocationCoordinate2D)coordForPixelPoint:(CGPoint)pixelPoint zoomLevel:(NSInteger)zoomLevel {
    
	CLLocationCoordinate2D coordinate;
	
	coordinate.longitude = (pixelPoint.x - centerPointOfTheEarth[zoomLevel].x) / pixelsPerDegreeLongitude[zoomLevel];
    coordinate.latitude = (2 * atan(exp((pixelPoint.y - centerPointOfTheEarth[zoomLevel].y) / -radiusOfTheEarth[zoomLevel])) - M_PI_2) / (M_PI / 180);
    
    return coordinate;
}

@end
