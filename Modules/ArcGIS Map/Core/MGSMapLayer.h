#import <UIKit/UIKit.h>

@class MGSMapAnnotation;
@class MGSMapCoordinate;
@class MGSMarker;
@class MGSMapView;

@protocol MGSCalloutController
- (BOOL)isPresentingCalloutForAnnotation:(MGSMapAnnotation*)annotation;
- (UIView*)viewForAnnotation:(MGSMapAnnotation*)annotation;
@end

@interface MGSMapLayer : NSObject
@property (strong) NSString *name;
@property (weak,readonly) MGSMapView *mapView;
@property (strong) UIViewController<MGSCalloutController> *calloutController;

@property (strong) NSArray *annotations;
@property (strong) MGSMarker *markerTemplate;
@property (assign,nonatomic) BOOL hidden;

- (void)addAnnotation:(MGSMapAnnotation*)annotation;
- (void)deleteAnnotation:(MGSMapAnnotation*)annotation;
- (void)deleteAllAnnotations;

- (id)initWithName:(NSString*)name;
- (void)refreshLayer;
@end
