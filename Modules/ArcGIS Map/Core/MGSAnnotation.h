#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class MGSMarker;

@protocol MGSAnnotation <NSObject>
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *detail;

@optional
@property (nonatomic, readonly, copy) MGSMarker *marker;
@property (nonatomic, readonly, copy) UIImage *image;
@property (nonatomic, readonly, weak) UIView *calloutView;
@property (nonatomic, readonly, weak) id<NSObject> userData;

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;
@end

@protocol MGSAnnotationView <NSObject>
- (void)prepareForReuseWithAnnotation:(id<MGSAnnotation>) annotation;
@end