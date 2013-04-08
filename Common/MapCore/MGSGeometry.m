#import "MGSGeometry.h"
#import "MGSSafeAnnotation.h"
#import "CoreLocation+MITAdditions.h"
#import "MapKit+MITAdditions.h"

const CLLocationCoordinate2D CLLocationCoordinate2DInvalid = {.longitude = CGFLOAT_MAX, .latitude = CGFLOAT_MAX};
const MKCoordinateRegion MKCoordinateRegionInvalid = {{.longitude = CGFLOAT_MAX,
                                                        .latitude = CGFLOAT_MAX},
                                                      {.latitudeDelta = CGFLOAT_MAX,
                                                        .longitudeDelta = CGFLOAT_MAX}};

FOUNDATION_EXPORT MKCoordinateRegion MKCoordinateRegionForMGSAnnotations(NSSet *annotations)
{
    NSMutableArray *coordinates = [NSMutableArray array];
    
    for (id<MGSAnnotation> annotation in annotations) {
        MGSSafeAnnotation *safeAnnotation = [[MGSSafeAnnotation alloc] initWithAnnotation:annotation];
        
        switch (safeAnnotation.annotationType) {
            case MGSAnnotationMarker:
            case MGSAnnotationPointOfInterest: {
                [coordinates addObject:[NSValue valueWithCLLocationCoordinate:safeAnnotation.coordinate]];
            }
                break;
                
            case MGSAnnotationPolygon:
            case MGSAnnotationPolyline: {
                if ([safeAnnotation.points count]) {
                    [coordinates addObjectsFromArray:safeAnnotation.points];
                }
            }
                break;
        }
    }
    
    return MKCoordinateRegionForCoordinates([NSSet setWithArray:coordinates]);
}