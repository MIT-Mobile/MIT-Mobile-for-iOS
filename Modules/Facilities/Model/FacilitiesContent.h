#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacilitiesLocation;
@class FacilitiesCategory;

@interface FacilitiesContent : NSManagedObject {
@private
}
@property (nonatomic, retain) NSArray * altname;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSURL * url;
@property (nonatomic, retain) NSSet* categories;
@property (nonatomic, retain) FacilitiesLocation * location;

- (void)addCategoriesObject:(FacilitiesCategory *)value;
- (void)removeCategoriesObject:(FacilitiesCategory *)value;
- (void)addCategories:(NSSet *)value;
- (void)removeCategories:(NSSet *)value;
@end
