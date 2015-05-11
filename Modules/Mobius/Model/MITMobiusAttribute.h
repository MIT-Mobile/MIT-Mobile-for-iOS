#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusAttributeValueSet, MITMobiusResource, MITMobiusAttributeValue, MITMobiusSearchOption, MITMobiusResourceAttributeValueSet;

typedef NS_ENUM(NSInteger, MITMobiusAttributeType) {
    MITMobiusAttributeTypeString,
    MITMobiusAttributeTypeNumeric,
    MITMobiusAttributeTypeAutocompletion,
    MITMobiusAttributeTypeText,
    MITMobiusAttributeTypeOptionSingle,
    MITMobiusAttributeTypeOptionMultiple
};

@interface MITMobiusAttribute : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * fieldType;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * valueSetName;
@property (nonatomic, retain) NSString * widgetType;
@property (nonatomic, retain) NSSet *resourceValues;
@property (nonatomic, retain) NSSet *searchOptions;
@property (nonatomic, retain) NSOrderedSet *values;

@property (nonatomic, readonly) MITMobiusAttributeType type;
@end

@interface MITMobiusAttribute (CoreDataGeneratedAccessors)

- (void)addResourceValuesObject:(MITMobiusResourceAttributeValueSet *)value;
- (void)removeResourceValuesObject:(MITMobiusResourceAttributeValueSet *)value;
- (void)addResourceValues:(NSSet *)values;
- (void)removeResourceValues:(NSSet *)values;

- (void)addSearchOptionsObject:(MITMobiusSearchOption *)value;
- (void)removeSearchOptionsObject:(MITMobiusSearchOption *)value;
- (void)addSearchOptions:(NSSet *)values;
- (void)removeSearchOptions:(NSSet *)values;

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

