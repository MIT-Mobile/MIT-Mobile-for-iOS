#import <CoreData/CoreData.h>

@class EventCategory;

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
@property (nonatomic, retain) NSNumber * isRegular;

- (NSString *)subtitle;
- (NSString *)dateStringWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle separator:(NSString *)separator ;
- (BOOL)hasCoords;
- (void)updateWithDict:(NSDictionary *)dict;

// wrapper for addCategoriesObject that sets isRegular
- (void)addCategory:(EventCategory *)category;

@end


@interface MITCalendarEvent (CoreDataGeneratedAccessors)
- (void)addCategoriesObject:(NSManagedObject *)value;
- (void)removeCategoriesObject:(NSManagedObject *)value;
- (void)addCategories:(NSSet *)value;
- (void)removeCategories:(NSSet *)value;

@end

