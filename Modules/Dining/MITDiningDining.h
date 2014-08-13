#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITDiningLinks, MITDiningVenues;

@interface MITDiningDining : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * announcementsHTML;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSSet *links;
@property (nonatomic, retain) MITDiningVenues *venues;
@end

@interface MITDiningDining (CoreDataGeneratedAccessors)

- (void)addLinksObject:(MITDiningLinks *)value;
- (void)removeLinksObject:(MITDiningLinks *)value;
- (void)addLinks:(NSSet *)values;
- (void)removeLinks:(NSSet *)values;

@end
