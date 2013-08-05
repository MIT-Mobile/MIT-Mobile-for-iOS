#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LibrariesLocationsHours, LibrariesLocationsHoursTermHours;

@interface LibrariesLocationsHoursTerm : NSManagedObject
@property (nonatomic, strong) NSDate * startDate;
@property (nonatomic, strong) NSDate * endDate;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, strong) NSNumber * termSortOrder;
@property (nonatomic, strong) LibrariesLocationsHours * library;
@property (nonatomic, copy) NSSet* hours;

@end
