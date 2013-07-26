#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacilitiesCategory, FacilitiesLocation;

@interface FacilitiesCategory : NSManagedObject
@property (nonatomic, strong) NSString * uid;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSSet * locationIds;
@property (nonatomic, strong) NSDate * lastUpdated;
@property (nonatomic, strong) NSSet* subcategories;
@property (nonatomic, strong) NSSet* locations;
@property (nonatomic, strong) FacilitiesCategory * parent;

- (void)addSubcategoriesObject:(FacilitiesCategory *)value;
- (void)removeSubcategoriesObject:(FacilitiesCategory *)value;
- (void)addSubcategories:(NSSet *)value;
- (void)removeSubcategories:(NSSet *)value;

- (void)addLocationsObject:(FacilitiesLocation *)value;
- (void)removeLocationsObject:(FacilitiesLocation *)value;
- (void)addLocations:(NSSet *)value;
- (void)removeLocations:(NSSet *)value;
@end
