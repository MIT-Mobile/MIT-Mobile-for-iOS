#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface MITMapPlace : NSObject <NSSecureCoding,NSCopying>
@property CLLocationCoordinate2D coordinate;

@property (copy) NSString* identifier;
@property (copy) NSString* buildingNumber;
@property (copy) NSString* name;

@property (copy) NSString* viewAngle;
@property (copy) NSURL* imageURL;

@property (copy) NSString* mailingAddress;
@property (copy) NSString* streetAddress;
@property (copy) NSString* city;

@property (copy) NSString* architect;
@property (copy) NSOrderedSet* contents;
@property (copy) NSOrderedSet* snippets;

- (id)init;
- (id)initWithDictionary:(NSDictionary*)dictionary;

- (NSDictionary*)dictionaryValue;
@end
