#import <CoreData/CoreData.h>

@class MITCalendarEvent;

@interface EventCategory :  NSManagedObject
@property (nonatomic, strong) NSNumber * catID;
@property (nonatomic, copy) NSString * listID;
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSSet* subCategories;
@property (nonatomic, strong) EventCategory * parentCategory;
@property (nonatomic, copy) NSSet* events;

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

