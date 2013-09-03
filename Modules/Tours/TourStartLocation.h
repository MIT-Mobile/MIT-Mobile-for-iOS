#import <CoreData/CoreData.h>
#import "TourComponent.h"

@class TourSiteOrRoute;

@interface TourStartLocation :  TourComponent  

@property (nonatomic, strong) TourSiteOrRoute * startSite;

@end



