#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusResourceAttributeValue, MITMobiusTemplateAttribute;

@interface MITMobiusResourceAttribute : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * templateAttributeIdentifier;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) MITMobiusTemplateAttribute *attribute;
@property (nonatomic, retain) NSOrderedSet *values;
@end

@interface MITMobiusResourceAttribute (CoreDataGeneratedAccessors)

- (void)insertObject:(MITMobiusResourceAttributeValue *)value inValuesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromValuesAtIndex:(NSUInteger)idx;
- (void)insertValues:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeValuesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInValuesAtIndex:(NSUInteger)idx withObject:(MITMobiusResourceAttributeValue *)value;
- (void)replaceValuesAtIndexes:(NSIndexSet *)indexes withValues:(NSArray *)values;
- (void)addValuesObject:(MITMobiusResourceAttributeValue *)value;
- (void)removeValuesObject:(MITMobiusResourceAttributeValue *)value;
- (void)addValues:(NSOrderedSet *)values;
- (void)removeValues:(NSOrderedSet *)values;
@end
