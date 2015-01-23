#import "MITMobileManagedResource.h"

@interface MITCalendarsCalendarsResource : MITMobileManagedResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;
@end

@interface MITCalendarsCalendarResource : MITMobileManagedResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;
@end

@interface MITCalendarsEventsResource : MITMobileManagedResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;
@end

@interface MITCalendarsEventResource : MITMobileManagedResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;
@end