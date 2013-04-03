#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

typedef double MGSZoomLevel;

FOUNDATION_EXPORT MKCoordinateRegion MKCoordinateRegionForMGSAnnotations(NSSet *annotations);

FOUNDATION_STATIC_INLINE MGSZoomLevel MGSZoomLevelForMKCoordinateSpan(MKCoordinateSpan span)
{
    return (MGSZoomLevel) (log2(360.0f / span.longitudeDelta) - 1.0);
}

FOUNDATION_STATIC_INLINE MKCoordinateSpan MKCoordinateSpanForMGSZoomLevel(MGSZoomLevel zoomLevel)
{
    CLLocationDegrees delta = (CLLocationDegrees) (360.0f / pow(2.0, zoomLevel + 1.0));
    return MKCoordinateSpanMake(delta, delta);
}

FOUNDATION_STATIC_INLINE BOOL MKCoordinateRegionIsValid(MKCoordinateRegion region) {
    return (CLLocationCoordinate2DIsValid(region.center) &&
            (region.span.latitudeDelta > 0.0) &&
            (region.span.latitudeDelta <= 90.0) &&
            (region.span.longitudeDelta > 0.0) &&
            (region.span.longitudeDelta <= 180.0));
}

FOUNDATION_STATIC_INLINE BOOL CGRectIsValid(CGRect rect) {
    CGRect normalizedRect = CGRectStandardize(rect);
    return !(CGRectIsEmpty(normalizedRect) ||
             CGRectIsInfinite(normalizedRect) ||
             CGRectIsNull(normalizedRect));
}