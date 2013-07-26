#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacilitiesLocation;
@class FacilitiesCategory;

@interface FacilitiesContent : NSManagedObject

@property (nonatomic, strong) NSArray * altname;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSURL * url;
@property (nonatomic, strong) NSSet* categories;
@property (nonatomic, strong) FacilitiesLocation * location;

- (void)addCategoriesObject:(FacilitiesCategory *)value;
- (void)removeCategoriesObject:(FacilitiesCategory *)value;
- (void)addCategories:(NSSet *)value;
- (void)removeCategories:(NSSet *)value;
@end
