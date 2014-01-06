#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreData/CoreData.h>
#import "MGSAnnotation.h"

@class MITMapPlace;
@class MITMapBookmark;

@interface MITMapPlace : NSManagedObject <MKAnnotation,MGSAnnotation>
@property (nonatomic, copy) NSString * identifier;
@property (nonatomic, copy) NSString * buildingNumber;
@property (nonatomic, copy) NSString * architect;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * mailingAddress;
@property (nonatomic, copy) NSString * city;
@property (nonatomic, copy) NSString * imageCaption;
@property (nonatomic, copy) NSURL * imageURL;
@property (nonatomic, copy) NSString * streetAddress;
@property (nonatomic, strong) NSNumber * longitude;
@property (nonatomic, strong) NSNumber * latitude;
@property (nonatomic, copy) NSURL * url;
@property (nonatomic, copy) NSOrderedSet *contents;
@property (nonatomic, strong) MITMapBookmark *bookmark;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

+ (NSString*)entityName;
@end

@interface MITMapPlace (CoreDataGeneratedAccessors)

- (void)addContentsObject:(MITMapPlace *)value;
- (void)removeContentsObject:(MITMapPlace *)value;
- (void)addContents:(NSOrderedSet *)values;
- (void)removeContents:(NSOrderedSet *)values;

@end
