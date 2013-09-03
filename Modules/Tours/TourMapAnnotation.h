#import <MapKit/MapKit.h>

#import "TourGeoLocation.h"

@class  TourComponent;

@interface TourMapAnnotation : NSObject <MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, strong) TourComponent *component;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, assign) BOOL hasTransform;
@property (nonatomic, assign) CGAffineTransform transform;
@property (nonatomic, strong) id<TourGeoLocation> tourGeoLocation;

@end
