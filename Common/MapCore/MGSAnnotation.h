#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MGSAnnotationTypes.h"

@class MGSMarker;


@protocol MGSAnnotation <NSObject>
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@optional
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *detail;
@property (nonatomic, readonly, strong) UIImage *calloutImage;

@property (nonatomic, readonly, strong) UIImage *markerImage;
@property (nonatomic, readonly) MGSMarkerOptions markerOptions;

@property (nonatomic, readonly) MGSAnnotationType annotationType;

// Used only when annotationType is a polygon or polyline
@property (nonatomic, readonly) NSArray* points;
@property (nonatomic, readonly) UIColor* strokeColor;
@property (nonatomic, readonly) UIColor* fillColor;
@property (nonatomic, readonly) CGFloat lineWidth;

@property (nonatomic, readonly, strong) id representedObject;
@end