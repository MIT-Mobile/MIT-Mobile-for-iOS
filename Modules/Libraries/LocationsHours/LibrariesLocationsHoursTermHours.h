#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "LibrariesLocationsHoursTerm.h"


@interface LibrariesLocationsHoursTermHours : NSManagedObject
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * hoursDescription;
@property (nonatomic, strong) NSNumber * sortOrder;
@property (nonatomic, strong) LibrariesLocationsHoursTerm * term;

@end
