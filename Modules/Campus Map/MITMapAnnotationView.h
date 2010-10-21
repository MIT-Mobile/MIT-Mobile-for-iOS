
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
	
	UIImageView* _shadowView;		// if a pin, this shadow will be animated onto the screen separately and then removed 
									// (when the pin is in position we replace its image with one that includes the shadow)
	BOOL _alreadyOnMap;				// indicates whether this annotation should be animated in (not _alreadyOnMap) or should simply follow the scroll (_alreadyOnMap).
	BOOL _hasBeenDropped;			// indicates whether this annotation has begun the pin drop animation
}

@property (nonatomic, retain) id<MKAnnotation> annotation;
@property BOOL canShowCallout;
@property (nonatomic, assign) MITMapView* mapView;
@property BOOL centeredVertically;
@property (nonatomic, retain) UIImageView* shadowView;
@property BOOL alreadyOnMap;
@property BOOL hasBeenDropped;

- (id)initWithAnnotation:(id <MKAnnotation>)annotation;


@end
