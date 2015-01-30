#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMartyResourceAttributeValue, MITMartyTemplateAttribute;

@interface MITMartyResourceAttribute : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * templateAttributeIdentifier;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) MITMartyTemplateAttribute *attribute;
@property (nonatomic, retain) NSOrderedSet *values;
@end

@interface MITMartyResourceAttribute (CoreDataGeneratedAccessors)

- (void)insertObject:(MITMartyResourceAttributeValue *)value inValuesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromValuesAtIndex:(NSUInteger)idx;
- (void)insertValues:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeValuesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInValuesAtIndex:(NSUInteger)idx withObject:(MITMartyResourceAttributeValue *)value;
- (void)replaceValuesAtIndexes:(NSIndexSet *)indexes withValues:(NSArray *)values;
- (void)addValuesObject:(MITMartyResourceAttributeValue *)value;
- (void)removeValuesObject:(MITMartyResourceAttributeValue *)value;
- (void)addValues:(NSOrderedSet *)values;
- (void)removeValues:(NSOrderedSet *)values;
@end
