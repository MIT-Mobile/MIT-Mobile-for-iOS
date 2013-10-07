#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

extern NSString* const MITMapPlaceContentURLKey;
extern NSString* const MITMapPlaceContentNameKey;

@interface MITMapPlace : NSObject <NSSecureCoding,NSCopying>
@property (readonly) CLLocationCoordinate2D coordinate;

@property (readonly,copy) NSString* identifier;
@property (readonly,copy) NSString* buildingNumber;
@property (readonly,copy) NSString* name;

@property (readonly,copy) NSString* viewAngle;
@property (readonly,copy) NSURL* imageURL;

@property (readonly,copy) NSString* mailingAddress;
@property (readonly,copy) NSString* streetAddress;
@property (readonly,copy) NSString* city;

@property (readonly,copy) NSString* architect;
@property (readonly,copy) NSOrderedSet* contents;
@property (readonly,copy) NSOrderedSet* snippets;

- (id)initWithDictionary:(NSDictionary*)dictionary;
- (NSDictionary*)dictionaryValue;
@end
