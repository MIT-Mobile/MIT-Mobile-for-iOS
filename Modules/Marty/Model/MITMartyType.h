#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITMobiusObject.h"

@class MITMobiusCategory, MITMartyResource, MITMartyTemplate;

@interface MITMartyType : MITMobiusObject

@property (nonatomic, retain) MITMobiusCategory *category;
@property (nonatomic, retain) NSSet *resources;
@property (nonatomic, retain) MITMartyTemplate *template;
@end

@interface MITMartyType (CoreDataGeneratedAccessors)

- (void)addResourcesObject:(MITMartyResource *)value;
- (void)removeResourcesObject:(MITMartyResource *)value;
- (void)addResources:(NSSet *)values;
- (void)removeResources:(NSSet *)values;

@end
