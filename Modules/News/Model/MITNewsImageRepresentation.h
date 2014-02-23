#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITNewsImage;

@interface MITNewsImageRepresentation : MITManagedObject <MITMappedObject>

@property (nonatomic, strong) NSNumber * height;
@property (nonatomic, strong) NSNumber * width;
@property (nonatomic, strong) NSURL * url;
@property (nonatomic, copy) NSSet *images;

@end

@interface MITNewsImageRepresentation (CoreDataGeneratedAccessors)

- (void)addImagesObject:(MITNewsImage *)value;
- (void)removeImagesObject:(MITNewsImage *)value;
- (void)addImages:(NSSet *)values;
- (void)removeImages:(NSSet *)values;

@end