#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITCalendarsEvent;

@interface MITCalendarsContact : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * websiteURL;
@property (nonatomic, retain) NSSet *events;

@end

@interface MITCalendarsContact (CoreDataGeneratedAccessors)

- (void)addEventObject:(MITCalendarsEvent *)value;
- (void)removeEventObject:(MITCalendarsEvent *)value;
- (void)addEvent:(NSSet *)values;
- (void)removeEvent:(NSSet *)values;

@end