#import <CoreData/CoreData.h>
#import <EventKit/EventKit.h>

@class EventCategory;
@class MITEventList;

@interface MITCalendarEvent :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * shortloc;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSDate * start;
@property (nonatomic, retain) NSDate * end;
@property (nonatomic, retain) NSNumber * eventID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSSet* categories;
@property (nonatomic, retain) NSDate * lastUpdated;
@property (nonatomic, retain) NSSet* lists;

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

