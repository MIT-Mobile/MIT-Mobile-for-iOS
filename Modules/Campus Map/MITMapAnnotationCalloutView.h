#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class MITMapView;
@class MITMapAnnotationView;

@interface MITMapAnnotationCalloutView : UIView
{
    MITMapAnnotationView *_annotationView;
	MITMapView *_mapView;
}

@property (nonatomic, retain) MITMapView *mapView;
@property (nonatomic, retain) MITMapAnnotationView *annotationView;

// Sets the origin of the callout (which should be the head of the pin).
//- (void)setOrigin:(CGPoint)origin;

// initialize the annotation callout with the annotation and the map view on which it is displayed. 
- (id)initWithAnnotationView:(MITMapAnnotationView *)annotationView mapView:(MITMapView*)mapView;


@end
