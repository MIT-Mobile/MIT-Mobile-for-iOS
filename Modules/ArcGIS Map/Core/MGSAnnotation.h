#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class MGSMarker;

typedef enum _MGSAnnotationType {
    MGSAnnotationMarker = 0,
    MGSAnnotationPoint,
    MGSAnnotationPolyline
} MGSAnnotationType;

@protocol MGSAnnotation <NSObject>
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@optional
@property (nonatomic, readonly, assign) BOOL canShowCallout;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *detail;
@property (nonatomic, readonly, strong) UIImage *calloutImage;
@property (nonatomic, readonly, strong) UIImage *annotationMarker;

@property (nonatomic, readonly, strong) UIView *calloutView;
@property (nonatomic, readonly) MGSAnnotationType annotationType;

@property (nonatomic, readonly, strong) id<NSObject> userData;
@end