#import <CoreData/CoreData.h>

@class MITCalendarEvent;

@interface MITEventList :  NSManagedObject
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * listID;
@property (nonatomic, copy) NSNumber * sortOrder;
@property (nonatomic, copy) NSSet* events;

@end


@interface MITEventList (CoreDataGeneratedAccessors)
- (void)addEventsObject:(MITCalendarEvent *)value;
- (void)removeEventsObject:(MITCalendarEvent *)value;
- (void)addEvents:(NSSet *)value;
- (void)removeEvents:(NSSet *)value;

@end

