#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITMobiusAttribute, MITMobiusAttributeValue, MITMobiusRecentSearchQuery;

@interface MITMobiusSearchOption : NSManagedObject

@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) NSOrderedSet *values;
@property (nonatomic, retain) MITMobiusRecentSearchQuery *query;
@property (nonatomic, retain) MITMobiusAttribute *attribute;
@end

@interface MITMobiusSearchOption (CoreDataGeneratedAccessors)

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
