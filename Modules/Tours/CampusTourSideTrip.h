#import <CoreData/CoreData.h>
#import "TourComponent.h"
#import "TourGeoLocation.h"

@class TourSiteOrRoute;

@interface CampusTourSideTrip :  TourComponent <TourGeoLocation>
{
}

@property (nonatomic, strong) TourSiteOrRoute * component;
@property (nonatomic, strong) NSNumber * longitude;
@property (nonatomic, strong) NSNumber * latitude;

@property (nonatomic, strong, readonly) TourSiteOrRoute * site;


@end
