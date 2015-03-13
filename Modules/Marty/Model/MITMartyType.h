#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITMobiusObject.h"

@class MITMobiusCategory, MITMobiusResource, MITMobiusTemplate;

@interface MITMartyType : MITMobiusObject

@property (nonatomic, retain) MITMobiusCategory *category;
@property (nonatomic, retain) NSSet *resources;
@property (nonatomic, retain) MITMobiusTemplate *template;
@end

@interface MITMartyType (CoreDataGeneratedAccessors)

- (void)addResourcesObject:(MITMobiusResource *)value;
- (void)removeResourcesObject:(MITMobiusResource *)value;
- (void)addResources:(NSSet *)values;
- (void)removeResources:(NSSet *)values;

@end
