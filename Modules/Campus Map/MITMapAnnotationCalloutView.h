#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MGSCalloutView.h"

@class MITMapView;
@class MITMapAnnotationView;

@interface MITMapAnnotationCalloutView : MGSCalloutView
@property (nonatomic, weak) MITMapView *mapView;
@property (nonatomic, strong) MITMapAnnotationView *annotationView;

// initialize the annotation callout with the annotation and the map view on which it is displayed. 
- (id)initWithAnnotationView:(MITMapAnnotationView *)annotationView
                     mapView:(MITMapView*)mapView;


@end
