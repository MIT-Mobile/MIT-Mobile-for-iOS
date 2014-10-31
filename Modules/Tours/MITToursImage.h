#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITToursImageRepresentation, MITToursStop;

@interface MITToursImage : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSSet *representations;
@property (nonatomic, retain) MITToursStop *stop;

@property (nonatomic, readonly) NSString *thumbnailURL;

@end

@interface MITToursImage (CoreDataGeneratedAccessors)

- (void)addRepresentationsObject:(MITToursImageRepresentation *)value;
- (void)removeRepresentationsObject:(MITToursImageRepresentation *)value;
- (void)addRepresentations:(NSSet *)values;
- (void)removeRepresentations:(NSSet *)values;

@end
