#import <MapKit/MapKit.h>

@class TourSiteOrRoute;

@interface TourSiteMapAnnotation : NSObject <MKAnnotation> {

    TourSiteOrRoute *site;
    NSString *subtitle;
    BOOL hasTransform;
    CGAffineTransform transform;

}

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, retain) TourSiteOrRoute *site;
@property (nonatomic, retain) NSString *subtitle;
@property (nonatomic) BOOL hasTransform;
@property (nonatomic) CGAffineTransform transform;

@end
