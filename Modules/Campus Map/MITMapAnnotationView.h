#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class MITMapView;

extern NSString* const kMITMapAnnotationViewTapped;

@interface MITMapAnnotationView : MKAnnotationView
@property (nonatomic, strong) id<MKAnnotation> annotation;
@property (nonatomic, weak) MITMapView* mapView;
@property (nonatomic) BOOL showsCustomCallout;
@property (nonatomic) BOOL centeredVertically;

@end


@interface MITPinAnnotationView : MITMapAnnotationView
@property (nonatomic) BOOL animatesDrop;
@property (nonatomic, strong) UIImageView* shadowView;

@end

