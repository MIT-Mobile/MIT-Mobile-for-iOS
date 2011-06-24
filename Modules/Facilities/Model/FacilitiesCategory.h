#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacilitiesCategory, FacilitiesLocation;

@interface FacilitiesCategory : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet * locationIds;
@property (nonatomic, retain) NSDate * lastUpdated;
@property (nonatomic, retain) NSSet* subcategories;
@property (nonatomic, retain) NSSet* locations;
@property (nonatomic, retain) FacilitiesCategory * parent;

- (void)addSubcategoriesObject:(FacilitiesCategory *)value;
- (void)removeSubcategoriesObject:(FacilitiesCategory *)value;
- (void)addSubcategories:(NSSet *)value;
- (void)removeSubcategories:(NSSet *)value;

- (void)addLocationsObject:(FacilitiesLocation *)value;
- (void)removeLocationsObject:(FacilitiesLocation *)value;
- (void)addLocations:(NSSet *)value;
- (void)removeLocations:(NSSet *)value;
@end
