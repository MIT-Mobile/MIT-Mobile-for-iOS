#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusResource, MITMobiusType;

@interface MITMobiusCategory : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * name;

@property (nonatomic, retain) NSSet *resources;
@property (nonatomic, retain) NSSet *types;
@end

@interface MITMobiusCategory (CoreDataGeneratedAccessors)

- (void)addResourcesObject:(MITMobiusResource *)value;
- (void)removeResourcesObject:(MITMobiusResource *)value;
- (void)addResources:(NSSet *)values;
- (void)removeResources:(NSSet *)values;

- (void)addTypesObject:(MITMobiusType *)value;
- (void)removeTypesObject:(MITMobiusType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

@end
