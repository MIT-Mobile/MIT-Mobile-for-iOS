#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITDiningLinks, MITDiningVenues;

@interface MITDiningDining : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * announcementsHTML;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSOrderedSet *links;
@property (nonatomic, retain) MITDiningVenues *venues;
@end

@interface MITDiningDining (CoreDataGeneratedAccessors)

- (void)insertObject:(MITDiningLinks *)value inLinksAtIndex:(NSUInteger)idx;
- (void)removeObjectFromLinksAtIndex:(NSUInteger)idx;
- (void)insertLinks:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeLinksAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInLinksAtIndex:(NSUInteger)idx withObject:(MITDiningLinks *)value;
- (void)replaceLinksAtIndexes:(NSIndexSet *)indexes withLinks:(NSArray *)values;
- (void)addLinksObject:(MITDiningLinks *)value;
- (void)removeLinksObject:(MITDiningLinks *)value;
- (void)addLinks:(NSOrderedSet *)values;
- (void)removeLinks:(NSOrderedSet *)values;
@end
