#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@class MITMobiusRecentSearchList,MITMobiusSearchOption;

@interface MITMobiusRecentSearchQuery : MITManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) MITMobiusRecentSearchList *search;
@property (nonatomic, retain) NSOrderedSet *options;

- (NSString*)URLParameterString;
@end

@interface MITMobiusRecentSearchQuery (CoreDataGeneratedAccessors)

- (void)insertObject:(MITMobiusSearchOption *)value inOptionsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromOptionsAtIndex:(NSUInteger)idx;
- (void)insertOptions:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeOptionsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInOptionsAtIndex:(NSUInteger)idx withObject:(MITMobiusSearchOption *)value;
- (void)replaceOptionsAtIndexes:(NSIndexSet *)indexes withOptions:(NSArray *)Options;
- (void)addOptionsObject:(MITMobiusSearchOption *)value;
- (void)removeOptionsObject:(MITMobiusSearchOption *)value;
- (void)addOptions:(NSOrderedSet *)options;
- (void)removeOptions:(NSOrderedSet *)options;

@end
