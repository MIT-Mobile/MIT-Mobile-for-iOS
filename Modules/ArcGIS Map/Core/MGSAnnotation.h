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
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *detail;
@property (nonatomic, readonly, copy) UIImage *image;
@property (nonatomic, readonly, weak) UIView *calloutView;

@property (nonatomic, readonly) MGSAnnotationType annotationType;

@property (nonatomic, readonly, weak) id<NSObject> userData;

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;
@end

@protocol MGSAnnotationView <NSObject>
- (void)prepareForReuseWithAnnotation:(id<MGSAnnotation>) annotation;
@end