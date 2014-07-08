#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@class MITMapPlace;
@class MITMapBookmark;
@class MITMapSearch;
@class MITMapCategory;

@interface MITMapPlace : MITManagedObject <MKAnnotation>

@property (nonatomic, copy) NSString * identifier;
@property (nonatomic, copy) NSString * buildingNumber;
@property (nonatomic, copy) NSString * architect;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * mailingAddress;
@property (nonatomic, copy) NSString * city;
@property (nonatomic, copy) NSString * imageCaption;
@property (nonatomic, copy) NSURL * imageURL;
@property (nonatomic, copy) NSString * streetAddress;
@property (nonatomic, strong) NSNumber * longitude;
@property (nonatomic, strong) NSNumber * latitude;
@property (nonatomic, strong) id categoryIds;
@property (nonatomic, copy) NSURL * url;
@property (nonatomic, copy) NSOrderedSet *categories;
@property (nonatomic, copy) NSOrderedSet *contents;
@property (nonatomic, strong) MITMapBookmark *bookmark;
@property (nonatomic, strong) MITMapSearch *search;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end

@interface MITMapPlace (CoreDataGeneratedAccessors)

- (void)insertObject:(MITMapCategory *)value inCategoriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCategoriesAtIndex:(NSUInteger)idx;
- (void)insertCategories:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCategoriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCategoriesAtIndex:(NSUInteger)idx withObject:(MITMapCategory *)value;
- (void)replaceCategoriesAtIndexes:(NSIndexSet *)indexes withCategories:(NSArray *)values;
- (void)addCategoriesObject:(MITMapCategory *)value;
- (void)removeCategoriesObject:(MITMapCategory *)value;
- (void)addCategories:(NSOrderedSet *)values;
- (void)removeCategories:(NSOrderedSet *)values;

- (void)addContentsObject:(MITMapPlace *)value;
- (void)removeContentsObject:(MITMapPlace *)value;
- (void)addContents:(NSOrderedSet *)values;
- (void)removeContents:(NSOrderedSet *)values;

@end
