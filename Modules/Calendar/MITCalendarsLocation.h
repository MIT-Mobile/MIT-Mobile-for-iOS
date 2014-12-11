#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITCalendarsEvent;

@interface MITCalendarsLocation : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * locationDescription;
@property (nonatomic, retain) NSString * roomNumber;
@property (nonatomic, retain) id coordinates;
@property (nonatomic, retain) NSSet *events;

- (NSString *)locationString;
- (NSString *)bestMapsSearchDescription;

@end

@interface MITCalendarsLocation (CoreDataGeneratedAccessors)

- (void)addEventsObject:(MITCalendarsEvent *)value;
- (void)removeEventsObject:(MITCalendarsEvent *)value;
- (void)addEvents:(NSSet *)values;
- (void)removeEvents:(NSSet *)values;

@end