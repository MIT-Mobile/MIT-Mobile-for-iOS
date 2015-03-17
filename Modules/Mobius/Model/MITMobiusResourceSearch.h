#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITMobiusResource;

@interface MITMobiusResourceSearch : NSManagedObject

@property (nonatomic, retain) NSString * query;
@property (nonatomic, retain) NSSet *resources;
@end

@interface MITMobiusResourceSearch (CoreDataGeneratedAccessors)

- (void)addResourcesObject:(MITMobiusResource *)value;
- (void)removeResourcesObject:(MITMobiusResource *)value;
- (void)addResources:(NSSet *)values;
- (void)removeResources:(NSSet *)values;

@end
