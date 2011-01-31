#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class MITMapView;

extern NSString* const kMITMapAnnotationViewTapped;

@interface MITMapAnnotationView : MKAnnotationView {

	id<MKAnnotation> _annotation;

    BOOL _showsCustomCallout;
	
	MITMapView* _mapView;
	
	// bool indicating if this view should be positioned based on its center or its bottom
	BOOL _centeredVertically;
}

@property (nonatomic, retain) id<MKAnnotation> annotation;
@property (nonatomic) BOOL showsCustomCallout;
@property (nonatomic, assign) MITMapView* mapView;
@property (nonatomic) BOOL centeredVertically;

@end


@interface MITPinAnnotationView : MITMapAnnotationView
{
    BOOL _animatesDrop;
	UIImageView* _shadowView;
}

@property (nonatomic) BOOL animatesDrop;
@property (nonatomic, retain) UIImageView* shadowView;

@end

