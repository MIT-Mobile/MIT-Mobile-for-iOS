#import "MITMobileManagedResource.h"

@interface MITCalendarsResource : MITMobileManagedResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;
@end

@interface MITCalendarResource : MITMobileManagedResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;
@end

@interface MITEventsResource : MITMobileManagedResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;
@end

@interface MITEventResource : MITMobileManagedResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;
@end