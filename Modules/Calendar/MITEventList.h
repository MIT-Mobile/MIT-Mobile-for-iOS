#import <CoreData/CoreData.h>

@class MITCalendarEvent;

@interface MITEventList :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * listID;
@property (nonatomic, retain) NSNumber * sortOrder;
@property (nonatomic, retain) NSSet* events;

@end


@interface MITEventList (CoreDataGeneratedAccessors)
- (void)addEventsObject:(MITCalendarEvent *)value;
- (void)removeEventsObject:(MITCalendarEvent *)value;
- (void)addEvents:(NSSet *)value;
- (void)removeEvents:(NSSet *)value;

@end

