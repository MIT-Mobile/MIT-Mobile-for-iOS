#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "MITMapAnnotationView.h"
#import "MGSSimpleAnnotation.h"

@class MITMapView;


@interface MITAnnotationAdaptor : MGSSimpleAnnotation
@property (nonatomic,strong) id<MKAnnotation> mkAnnotation;
@property (nonatomic,weak) MITMapView *mapView;
@property (nonatomic,strong) MITMapAnnotationView *annotationView;

- (id)initWithMKAnnotation:(id<MKAnnotation>)annotation;
@end