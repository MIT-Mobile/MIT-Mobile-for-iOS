#import <CoreData/CoreData.h>
#import "TourComponent.h"

@class TourSiteOrRoute;

@interface TourStartLocation :  TourComponent  
{
}

@property (nonatomic, retain) TourSiteOrRoute * startSite;

@end



