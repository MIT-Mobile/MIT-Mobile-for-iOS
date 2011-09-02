#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LibrariesLocationsHours, LibrariesLocationsHoursTermHours;

@interface LibrariesLocationsHoursTerm : NSManagedObject {
@private
}
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * termSortOrder;
@property (nonatomic, retain) LibrariesLocationsHours * library;
@property (nonatomic, retain) NSSet* hours;

@end
