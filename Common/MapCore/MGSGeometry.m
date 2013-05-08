#import "MGSGeometry.h"
#import "MGSSafeAnnotation.h"
#import "CoreLocation+MITAdditions.h"
#import "MapKit+MITAdditions.h"


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