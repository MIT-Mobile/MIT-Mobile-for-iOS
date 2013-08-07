#import <CoreData/CoreData.h>
#import <EventKit/EventKit.h>

@class EventCategory;
@class MITEventList;

@interface MITCalendarEvent :  NSManagedObject
@property (nonatomic, copy) NSString * location;
@property (nonatomic, copy) NSString * shortloc;
@property (nonatomic, strong) NSNumber * latitude;
@property (nonatomic, strong) NSNumber * longitude;
@property (nonatomic, strong) NSDate * start;
@property (nonatomic, strong) NSDate * end;
@property (nonatomic, strong) NSNumber * eventID;
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * phone;
@property (nonatomic, copy) NSString * summary;
@property (nonatomic, copy) NSString * url;
@property (nonatomic, copy) NSSet* categories;
@property (nonatomic, strong) NSDate * lastUpdated;
@property (nonatomic, copy) NSSet* lists;

- (NSString *)subtitle;
- (NSString *)dateStringWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle separator:(NSString *)separator ;
- (BOOL)hasCoords;
- (void)updateWithDict:(NSDictionary *)dict;
- (BOOL)hasMoreDetails;
- (void)setUpEKEvent:(EKEvent *)ekEvent;

@end


@interface MITCalendarEvent (CoreDataGeneratedAccessors)
- (void)addCategoriesObject:(EventCategory *)value;
- (void)removeCategoriesObject:(EventCategory *)value;
- (void)addCategories:(NSSet *)value;
- (void)removeCategories:(NSSet *)value;

- (void)addListsObject:(MITEventList *)value;
- (void)removeListsObject:(MITEventList *)value;
- (void)addLists:(NSSet *)value;
- (void)removeLists:(NSSet *)value;

@end

