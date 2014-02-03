#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITNewsImageRepresentation, MITNewsStory;

@interface MITNewsImage : MITManagedObject <MITMappedObject>

@property (nonatomic, copy) NSString * credits;
@property (nonatomic, copy) NSString * caption;
@property (nonatomic, copy) NSString * descriptionText; //Named a bit oddly because 'description' conflicts with -[NSObject description]
@property (nonatomic, copy) NSSet *representations;
@property (nonatomic, copy) NSSet *gallery;
@property (nonatomic, strong) MITNewsStory *cover;

- (MITNewsImageRepresentation*)bestImageForSize:(CGSize)size;
@end

@interface MITNewsImage (CoreDataGeneratedAccessors)

- (void)addRepresentationsObject:(MITNewsImageRepresentation *)value;
- (void)removeRepresentationsObject:(MITNewsImageRepresentation *)value;
- (void)addRepresentations:(NSSet *)values;
- (void)removeRepresentations:(NSSet *)values;

- (void)addGalleryObject:(MITNewsStory *)value;
- (void)removeGalleryObject:(MITNewsStory *)value;
- (void)addGallery:(NSSet *)values;
- (void)removeGallery:(NSSet *)values;

@end
