#import <MapKit/MapKit.h>

#import "TourGeoLocation.h"

@interface TourMapAnnotation : NSObject <MKAnnotation> {

    NSString *title;
    NSString *subtitle;
    BOOL hasTransform;
    CGAffineTransform transform;
    id<TourGeoLocation> tourGeoLocation;

}

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;
@property (nonatomic) BOOL hasTransform;
@property (nonatomic) CGAffineTransform transform;
@property (nonatomic, retain) id<TourGeoLocation> tourGeoLocation;

@end
