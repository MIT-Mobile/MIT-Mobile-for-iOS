#import "MGSGeometry.h"
#import "MGSSafeAnnotation.h"
#import "CoreLocation+MITAdditions.h"
#import "MapKit+MITAdditions.h"


MKCoordinateRegion MKCoordinateRegionForMGSAnnotations(NSSet *annotations)
{
    NSMutableArray *coordinates = [NSMutableArray array];
    
    for (id<MGSAnnotation> annotation in annotations) {
        MGSSafeAnnotation *safeAnnotation = [[MGSSafeAnnotation alloc] initWithAnnotation:annotation];
        
        switch (safeAnnotation.annotationType) {
            case MGSAnnotationMarker:
            case MGSAnnotationPointOfInterest: {
                [coordinates addObject:[NSValue valueWithMKCoordinate:safeAnnotation.coordinate]];
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
    
    
    // Use the default padding and minimum region size
    return MKCoordinateRegionForCoordinates([NSSet setWithArray:coordinates]);
}

MKCoordinateRegion MKCoordinateRegionForMGSAnnotationsWithPadding(NSSet *annotations, CGFloat padding, CLLocationDistance minimumRegionSize)
{
    NSMutableArray *coordinates = [NSMutableArray array];
    
    for (id<MGSAnnotation> annotation in annotations) {
        MGSSafeAnnotation *safeAnnotation = [[MGSSafeAnnotation alloc] initWithAnnotation:annotation];
        
        switch (safeAnnotation.annotationType) {
            case MGSAnnotationMarker:
            case MGSAnnotationPointOfInterest: {
                [coordinates addObject:[NSValue valueWithMKCoordinate:safeAnnotation.coordinate]];
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
    
    return MKCoordinateRegionForCoordinatesWithPadding([NSSet setWithArray:coordinates],padding,minimumRegionSize);
}