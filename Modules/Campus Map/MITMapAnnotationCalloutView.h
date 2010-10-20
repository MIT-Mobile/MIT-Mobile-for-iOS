#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class MITMapView;

@interface MITMapAnnotationCalloutView : UIView
{
	id <MKAnnotation> _annotation;
	
	UIImage* _calloutAccessoryImage;
	
	MITMapView* _mapView;
}


@property (retain) id <MKAnnotation> annotation;

// Sets the origin of the callout (which should be the head of the pin).
- (void)setOrigin:(CGPoint)origin;

// initialize the annotation callout with the annotation and the map view on which it is displayed. 
- (id)initWithAnnotation:(id <MKAnnotation>)annotation andMapView:(MITMapView*)mapView;


@end
