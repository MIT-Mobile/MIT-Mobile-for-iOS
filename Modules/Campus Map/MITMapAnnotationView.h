
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class MITMapView;

extern NSString* const kMITMapAnnotationViewTapped;

@interface MITMapAnnotationView : UIView {

	id<MKAnnotation> _annotation;
	
	BOOL _canShowCallout;
	
	MITMapView* _mapView;
	
	// bool indicating if this view should be positioned based on its center or its bottom
	BOOL _centeredVertically;
}

@property (nonatomic, retain) id<MKAnnotation> annotation;
@property BOOL canShowCallout;
@property (nonatomic, assign) MITMapView* mapView;
@property BOOL centeredVertically;

- (id)initWithAnnotation:(id <MKAnnotation>)annotation;


@end
