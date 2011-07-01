#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacilitiesContent, FacilitiesPropertyOwner;

@interface FacilitiesLocation : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSDate * roomsUpdated;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * isHiddenInBldgServices;
@property (nonatomic, retain) NSNumber * isLeased;
@property (nonatomic, retain) NSSet *categories;
@property (nonatomic, retain) NSSet *contents;
@property (nonatomic, retain) FacilitiesPropertyOwner *propertyOwner;

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
