#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacilitiesContent, FacilitiesPropertyOwner;

@interface FacilitiesLocation : NSManagedObject

@property (nonatomic, strong) NSString * number;
@property (nonatomic, strong) NSString * uid;
@property (nonatomic, strong) NSNumber * longitude;
@property (nonatomic, strong) NSNumber * latitude;
@property (nonatomic, strong) NSDate * roomsUpdated;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSNumber * isHiddenInBldgServices;
@property (nonatomic, strong) NSNumber * isLeased;
@property (nonatomic, strong) NSSet *categories;
@property (nonatomic, strong) NSSet *contents;
@property (nonatomic, strong) FacilitiesPropertyOwner *propertyOwner;

- (NSString*)displayString;
@end

@interface FacilitiesLocation (CoreDataGeneratedAccessors)

- (void)addCategoriesObject:(NSManagedObject *)value;
- (void)removeCategoriesObject:(NSManagedObject *)value;
- (void)addCategories:(NSSet *)values;
- (void)removeCategories:(NSSet *)values;
- (void)addContentsObject:(FacilitiesContent *)value;
- (void)removeContentsObject:(FacilitiesContent *)value;
- (void)addContents:(NSSet *)values;
- (void)removeContents:(NSSet *)values;
@end
