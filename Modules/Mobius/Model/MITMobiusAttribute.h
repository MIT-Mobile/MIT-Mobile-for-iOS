#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusAttributeValueSet, MITMobiusResource, MITMobiusAttributeValue;

@interface MITMobiusAttribute : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * fieldType;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * widgetType;
@property (nonatomic, retain) NSSet *resources;
@property (nonatomic, retain) NSString *valueSetName;
@property (nonatomic, retain) NSOrderedSet *values;
@end

@interface MITMobiusAttribute (CoreDataGeneratedAccessors)

- (void)addResourcesObject:(MITMobiusResource *)value;
- (void)removeResourcesObject:(MITMobiusResource *)value;
- (void)addResources:(NSSet *)values;
- (void)removeResources:(NSSet *)values;

- (void)insertObject:(MITMobiusAttributeValue *)value inValuesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromValuesAtIndex:(NSUInteger)idx;
- (void)insertValues:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeValuesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInValuesAtIndex:(NSUInteger)idx withObject:(MITMobiusAttributeValue *)value;
- (void)replaceValuesAtIndexes:(NSIndexSet *)indexes withValues:(NSArray *)values;
- (void)addValuesObject:(MITMobiusAttributeValue *)value;
- (void)removeValuesObject:(MITMobiusAttributeValue *)value;
- (void)addValues:(NSOrderedSet *)values;
- (void)removeValues:(NSOrderedSet *)values;

@end
