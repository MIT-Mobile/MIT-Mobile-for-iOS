#import <CoreData/CoreData.h>

@class CampusTour;

@interface TourLink :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) CampusTour * tour;
@property (nonatomic, retain) NSNumber * sortOrder;

@end



