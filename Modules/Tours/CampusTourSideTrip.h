#import <CoreData/CoreData.h>
#import "TourComponent.h"
#import "TourGeoLocation.h"

@class TourSiteOrRoute;

@interface CampusTourSideTrip :  TourComponent <TourGeoLocation>
{
}

@property (nonatomic, retain) TourSiteOrRoute * component;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * latitude;

@property (readonly) TourSiteOrRoute * site;


@end
