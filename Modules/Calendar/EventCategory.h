#import <CoreData/CoreData.h>

@class MITCalendarEvent;

@interface EventCategory :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * catID;
@property (nonatomic, retain) NSString * listID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet* subCategories;
@property (nonatomic, retain) EventCategory * parentCategory;
@property (nonatomic, retain) NSSet* events;

- (BOOL)hasSubCategories;
- (void)updateWithDict:(NSDictionary *)dict forListID:(NSString *)listID;

@end


@interface EventCategory (CoreDataGeneratedAccessors)
- (void)addSubCategoriesObject:(EventCategory *)value;
- (void)removeSubCategoriesObject:(EventCategory *)value;
- (void)addSubCategories:(NSSet *)value;
- (void)removeSubCategories:(NSSet *)value;

- (void)addEventsObject:(MITCalendarEvent *)value;
- (void)removeEventsObject:(MITCalendarEvent *)value;
- (void)addEvents:(NSSet *)value;
- (void)removeEvents:(NSSet *)value;

@end

