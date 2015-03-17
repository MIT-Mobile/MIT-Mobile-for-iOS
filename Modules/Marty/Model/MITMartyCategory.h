#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITMartyObject.h"
#import <MapKit/MapKit.h>

@class MITMartyResource, MITMartyTemplate, MITMartyType;

@interface MITMartyCategory : MITMartyObject <MKAnnotation>

@property (nonatomic, retain) NSSet *resources;
@property (nonatomic, retain) MITMartyTemplate *template;
@property (nonatomic, retain) NSSet *types;
@property (nonatomic, retain) NSString *templateIdentifier;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end

@interface MITMartyCategory (CoreDataGeneratedAccessors)

- (void)addResourcesObject:(MITMartyResource *)value;
- (void)removeResourcesObject:(MITMartyResource *)value;
- (void)addResources:(NSSet *)values;
- (void)removeResources:(NSSet *)values;

- (void)addTypesObject:(MITMartyType *)value;
- (void)removeTypesObject:(MITMartyType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

@end
