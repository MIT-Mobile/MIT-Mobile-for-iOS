#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MGSAnnotation.h"

FOUNDATION_EXTERN NSString* const MGSAnnotationAttributeKey;

typedef enum _MGSGraphicType {
    MGSGraphicDefault = 0,
    MGSGraphicStop
} MGSGraphicType;

FOUNDATION_EXPORT AGSPoint* AGSPointFromCLLocationCoordinate2D(CLLocationCoordinate2D coord);
FOUNDATION_EXPORT AGSPoint* AGSPointFromCLLocationCoordinate2DInSpatialReference(CLLocationCoordinate2D coord, AGSSpatialReference *targetReference);
FOUNDATION_EXPORT CLLocationCoordinate2D CLLocationCoordinate2DFromAGSPoint(AGSPoint *point);