#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusCategory, MITMobiusResource;

@interface MITMobiusType : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * categoryIdentifier;
@property (nonatomic, retain) MITMobiusCategory *category;
@property (nonatomic, retain) NSSet *resources;
@end

@interface MITMobiusType (CoreDataGeneratedAccessors)

- (void)addResourcesObject:(MITMobiusResource *)value;
- (void)removeResourcesObject:(MITMobiusResource *)value;
- (void)addResources:(NSSet *)values;
- (void)removeResources:(NSSet *)values;

@end
