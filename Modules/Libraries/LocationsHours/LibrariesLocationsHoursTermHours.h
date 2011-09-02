#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "LibrariesLocationsHoursTerm.h"


@interface LibrariesLocationsHoursTermHours : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * hoursDescription;
@property (nonatomic, retain) NSNumber * sortOrder;
@property (nonatomic, retain) LibrariesLocationsHoursTerm * term;

@end
