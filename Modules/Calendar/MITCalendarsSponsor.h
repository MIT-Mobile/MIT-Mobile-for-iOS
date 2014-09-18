#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITCalendarsEvent;

@interface MITCalendarsSponsor : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * groupID;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * websiteURL;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSSet *events;

@end

@interface MITCalendarsSponsor (CoreDataGeneratedAccessors)

- (void)addEventsObject:(MITCalendarsEvent *)value;
- (void)removeEventsObject:(MITCalendarsEvent *)value;
- (void)addEvents:(NSSet *)values;
- (void)removeEvents:(NSSet *)values;

@end