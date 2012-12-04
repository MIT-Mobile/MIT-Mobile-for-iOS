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

FOUNDATION_EXPORT AGSPoint* AGSPointFromCLLocationCoordinate(CLLocationCoordinate2D coord);
FOUNDATION_EXPORT CLLocationCoordinate2D CLLocationCoordinateFromAGSPoint(AGSPoint *point);
FOUNDATION_EXPORT AGSSymbol* AGSSymbolFromAnnotation(id<MGSAnnotation> annotation, MGSMarker *templateMarker);
FOUNDATION_EXPORT AGSGraphic* AGSGraphicFromAnnotation(id<MGSAnnotation> annotation, MGSGraphicType graphicType, MGSMarker *template);