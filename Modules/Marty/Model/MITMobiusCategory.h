#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITMobiusObject.h"

@class MITMobiusResource, MITMartyTemplate, MITMartyType;

@interface MITMobiusCategory : MITMobiusObject

@property (nonatomic, retain) NSSet *resources;
@property (nonatomic, retain) MITMartyTemplate *template;
@property (nonatomic, retain) NSSet *types;
@property (nonatomic, retain) NSString *templateIdentifier;
@end

@interface MITMobiusCategory (CoreDataGeneratedAccessors)

- (void)addResourcesObject:(MITMobiusResource *)value;
- (void)removeResourcesObject:(MITMobiusResource *)value;
- (void)addResources:(NSSet *)values;
- (void)removeResources:(NSSet *)values;

- (void)addTypesObject:(MITMartyType *)value;
- (void)removeTypesObject:(MITMartyType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

@end
