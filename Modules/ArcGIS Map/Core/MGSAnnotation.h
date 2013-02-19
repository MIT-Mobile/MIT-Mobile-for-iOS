#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class MGSMarker;

typedef enum _MGSAnnotationType {
    // Indicates the annotation should place a marker on the map
    // The maker will be the default pin unless the markerImage
    // image property returns a non-nil value. A marker is the only object
    // that can pop up a callout. By default, markers will respond to taps.
    MGSAnnotationMarker = 0x00,
    
    // Indicates that the annotation should draw a line to the map.
    // A polyline requires that the points property return an array of
    // NSValue objects containing CLLocationCoordinate2D points. If points
    // is nil or contains no data, the object will not be added to the map.
    // If the coordinate returns a valid CLLocationCoordinate2D point (verified
    // by CLLocationCoordinate2DIsValid), then the values in the 'points'
    // property are assumed to be relative offsets from the 'coordinate'
    MGSAnnotationPolyline = 0x01,
    MGSAnnotationPolygon = 0x02,
    
    // Indicates that the annotation is a marker for some sort of
    // pre-existing data on the layer. For example, if we were to 
    MGSAnnotationPointOfInterest = 0x04
} MGSAnnotationType;

@protocol MGSAnnotation <NSObject>
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@optional
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *detail;
@property (nonatomic, readonly, strong) UIImage *calloutImage;
@property (nonatomic, readonly, strong) UIImage *markerImage;

@property (nonatomic, readonly) MGSAnnotationType annotationType;

// Used only when annotationType is a polygon or polyline
@property (nonatomic, readonly) NSArray* points;
@property (nonatomic, readonly) UIColor* strokeColor;
@property (nonatomic, readonly) UIColor* fillColor;
@property (nonatomic, readonly) CGFloat lineWidth;

@property (nonatomic, readonly, strong) id<NSObject> userData;
@end