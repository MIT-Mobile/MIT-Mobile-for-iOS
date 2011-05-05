#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface FacilitiesLocation : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSSet* categories;

- (void)addCategoriesObject:(NSManagedObject *)value;
- (void)removeCategoriesObject:(NSManagedObject *)value;
- (void)addCategories:(NSSet *)value;
- (void)removeCategories:(NSSet *)value;

@end
