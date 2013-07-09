#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "CoreLocation+MITAdditions.h"
#import "MapKit+MITAdditions.h"

typedef double MGSZoomLevel;

/**  Returns a region that contains all of the annotation's coordinates with the default padding
 and minimum region values. This function does not require that all of the annotations are
 on the same layer.
 
 @param A set of MGSAnnotation objects.
 @return A square region encompassing all of the specified annotation's coordinates.
 @see MKCoordinateRegionForMGSAnnotationsWithPadding
 */
FOUNDATION_EXPORT MKCoordinateRegion MKCoordinateRegionForMGSAnnotations(NSSet *annotations);

/** Returns a region that contains all of the annotation's coordinates with the specified padding
 and minimum square region width. This function does not require that all of the annotations are
 on the same layer.
 
 This method does not take the marker icons into account so annotations with larger may need to
 increase the amount of padding used.
 
 @param annotations The set of MGSAnnotation objects to fit a region to
 @param padding The amount of padding for the region. The padding is a percentage of the calculated region and should be between 0 and 1.
 @param minimumRegionWidth The minimum size for the height and width of the region
 @return A square region encompassing all of the specified annotation's coordinates.
 */
FOUNDATION_EXPORT MKCoordinateRegion MKCoordinateRegionForMGSAnnotationsWithPadding(NSSet *annotations, CGFloat padding, CLLocationDistance minimumRegionSize);

FOUNDATION_STATIC_INLINE MGSZoomLevel MGSZoomLevelForMKCoordinateSpan(MKCoordinateSpan span)
{
    return (MGSZoomLevel) (log2(360.0f / span.longitudeDelta) - 1.0);
}

FOUNDATION_STATIC_INLINE MKCoordinateSpan MKCoordinateSpanForMGSZoomLevel(MGSZoomLevel zoomLevel)
{
    CLLocationDegrees delta = (CLLocationDegrees) (360.0f / pow(2.0, zoomLevel + 1.0));
    return MKCoordinateSpanMake(delta, delta);
}

FOUNDATION_STATIC_INLINE BOOL CGRectIsValid(CGRect rect) {
    CGRect normalizedRect = CGRectStandardize(rect);
    return !(CGRectIsEmpty(normalizedRect) ||
             CGRectIsInfinite(normalizedRect) ||
             CGRectIsNull(normalizedRect));
}