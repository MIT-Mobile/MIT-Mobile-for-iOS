#import <CoreData/CoreData.h>
#import "TourComponent.h"

@class TourSiteOrRoute;

@interface CampusTourSideTrip :  TourComponent  
{
}

@property (nonatomic, retain) TourSiteOrRoute * component;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * latitude;


@end
