#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITMartyObject.h"

@class MITMartyCategory, MITMartyResource, MITMartyTemplate;

@interface MITMartyType : MITMartyObject

@property (nonatomic, retain) MITMartyCategory *category;
@property (nonatomic, retain) NSSet *resources;
@property (nonatomic, retain) MITMartyTemplate *template;
@end

@interface MITMartyType (CoreDataGeneratedAccessors)

- (void)addResourcesObject:(MITMartyResource *)value;
- (void)removeResourcesObject:(MITMartyResource *)value;
- (void)addResources:(NSSet *)values;
- (void)removeResources:(NSSet *)values;

@end
