#import <MapKit/MapKit.h>
#import "MITMapPlace.h"
#import "MITAdditions.h"

static NSString* const MITMapPlaceIdentifierKey = @"id";
static NSString* const MITMapPlaceNameKey = @"name";
static NSString* const MITMapPlaceBuildingNumberKey = @"bldgnum";

static NSString* const MITMapPlaceImageURLKey = @"bldgimg";
static NSString* const MITMapPlaceImageViewAngleKey = @"viewangle";

static NSString* const MITMapPlaceArchitectKey = @"architect";
static NSString* const MITMapPlaceMailingAddressKey = @"mailing";
static NSString* const MITMapPlaceStreetAddressKey = @"street";
static NSString* const MITMapPlaceCityKey = @"city";

static NSString* const MITMapPlaceLatitudeCoordinateKey = @"lat_wgs84";
static NSString* const MITMapPlaceLongitudeCoordinateKey = @"long_wgs84";
static NSString* const MITMapPlaceCoordinateKey = @"coordinate"; // Used when encoding/decoding objects, not returned
                                                                 //  by any API calls (as of APIv2)

static NSString* const MITMapPlaceContentsKey = @"contents";
static NSString* const MITMapPlaceContentURLKey = @"url";
static NSString* const MITMapPlaceContentNameKey = @"name";

static NSString* const MITMapPlaceSnippetsKey = @"snippets";

@interface MITMapPlace ()
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
@end

@implementation MITMapPlace
+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (id)init
{
    self = [super init];
    if (self) {
        _coordinate = kCLLocationCoordinate2DInvalid;
    }

    return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [self init];
    if (self) {
        self.architect = dictionary[MITMapPlaceArchitectKey];
        self.buildingNumber = dictionary[MITMapPlaceBuildingNumberKey];
        self.city = dictionary[MITMapPlaceCityKey];
        self.identifier = dictionary[MITMapPlaceIdentifierKey];
        self.imageURL = [NSURL URLWithString:dictionary[MITMapPlaceImageURLKey]];
        self.mailingAddress = dictionary[MITMapPlaceMailingAddressKey];
        self.name = dictionary[MITMapPlaceNameKey];
        self.streetAddress = dictionary[MITMapPlaceStreetAddressKey];
        self.viewAngle = dictionary[MITMapPlaceImageViewAngleKey];


        if (dictionary[MITMapPlaceLatitudeCoordinateKey] && dictionary[MITMapPlaceLongitudeCoordinateKey]) {
            CLLocationDegrees latitude = [dictionary[MITMapPlaceLatitudeCoordinateKey] doubleValue];
            CLLocationDegrees longitude = [dictionary[MITMapPlaceLongitudeCoordinateKey] doubleValue];
            self.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        } else {
            self.coordinate = kCLLocationCoordinate2DInvalid;
        }


        if (dictionary[MITMapPlaceContentsKey]) {
            self.contents = [[NSOrderedSet alloc] initWithArray:dictionary[MITMapPlaceContentsKey]];
        }

        if (dictionary[MITMapPlaceSnippetsKey]) {
            self.snippets = [[NSOrderedSet alloc] initWithArray:dictionary[MITMapPlaceSnippetsKey]];
        }
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];

    if (self) {
        self.architect = [aDecoder decodeObjectOfClass:[NSString class] forKey:MITMapPlaceArchitectKey];
        self.buildingNumber = [aDecoder decodeObjectOfClass:[NSString class] forKey:MITMapPlaceBuildingNumberKey];
        self.city = [aDecoder decodeObjectOfClass:[NSString class] forKey:MITMapPlaceCityKey];
        self.identifier = [aDecoder decodeObjectOfClass:[NSString class] forKey:MITMapPlaceIdentifierKey];
        self.imageURL = [aDecoder decodeObjectOfClass:[NSURL class] forKey:MITMapPlaceImageURLKey];
        self.mailingAddress = [aDecoder decodeObjectOfClass:[NSString class] forKey:MITMapPlaceMailingAddressKey];
        self.name = [aDecoder decodeObjectOfClass:[NSString class] forKey:MITMapPlaceNameKey];
        self.streetAddress = [aDecoder decodeObjectOfClass:[NSString class] forKey:MITMapPlaceStreetAddressKey];
        self.viewAngle = [aDecoder decodeObjectOfClass:[NSString class] forKey:MITMapPlaceImageViewAngleKey];

        NSValue *coordinateValue = [aDecoder decodeObjectOfClass:[NSValue class] forKey:MITMapPlaceCoordinateKey];
        self.coordinate = [coordinateValue MKCoordinateValue];

        self.contents = [aDecoder decodeObjectOfClass:[NSOrderedSet class] forKey:MITMapPlaceContentsKey];
        self.snippets = [aDecoder decodeObjectOfClass:[NSOrderedSet class] forKey:MITMapPlaceSnippetsKey];
    }

    return self;

}

- (BOOL)isEqual:(id)object
{
    if (![super isEqual:object]) {
        if ([object isKindOfClass:[self class]]) {
            return [self isEqualToPlace:(MITMapPlace*)object];
        } else {
            return NO;
        }
    } else {
        return YES;
    }
}

- (BOOL)isEqualToPlace:(MITMapPlace*)otherPlace
{
    return [self.identifier isEqualToString:otherPlace.identifier];
}

- (NSUInteger)hash
{
    return [self.identifier hash];
}

- (id)copyWithZone:(NSZone *)zone
{
    NSDictionary *dictionaryValue = [self dictionaryValue];

    return [[[self class] allocWithZone:zone] initWithDictionary:dictionaryValue];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.architect forKey:MITMapPlaceArchitectKey];
    [aCoder encodeObject:self.buildingNumber forKey:MITMapPlaceBuildingNumberKey];
    [aCoder encodeObject:self.city forKey:MITMapPlaceCityKey];
    [aCoder encodeObject:self.identifier forKey:MITMapPlaceIdentifierKey];
    [aCoder encodeObject:self.imageURL forKey:MITMapPlaceImageURLKey];
    [aCoder encodeObject:self.mailingAddress forKey:MITMapPlaceMailingAddressKey];
    [aCoder encodeObject:self.name forKey:MITMapPlaceNameKey];
    [aCoder encodeObject:self.streetAddress forKey:MITMapPlaceStreetAddressKey];
    [aCoder encodeObject:self.viewAngle forKey:MITMapPlaceImageViewAngleKey];

    [aCoder encodeObject:[NSValue valueWithMKCoordinate:self.coordinate] forKey:MITMapPlaceCoordinateKey];
    [aCoder encodeObject:self.contents forKey:MITMapPlaceContentsKey];
    [aCoder encodeObject:self.snippets forKey:MITMapPlaceSnippetsKey];
}

- (NSDictionary*)dictionaryValue
{
    // Be neurotic when performing the below assignments and just
    // sanity check *everything*.
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];

    if (self.architect) {
        dictionary[MITMapPlaceArchitectKey] = self.architect;
    }

    if (self.buildingNumber) {
        dictionary[MITMapPlaceBuildingNumberKey] = self.buildingNumber;
    }

    if (self.city) {
        dictionary[MITMapPlaceCityKey] = self.city;
    }

    if (self.identifier) {
        dictionary[MITMapPlaceIdentifierKey] = self.identifier;
    }

    if (self.imageURL) {
        dictionary[MITMapPlaceImageURLKey] = self.imageURL;
    }

    if (self.mailingAddress) {
        dictionary[MITMapPlaceMailingAddressKey] = self.mailingAddress;
    }

    if (self.name) {
        dictionary[MITMapPlaceNameKey] = self.name;
    }

    if (self.streetAddress) {
        dictionary[MITMapPlaceStreetAddressKey] = self.streetAddress;
    }

    if (self.viewAngle) {
        dictionary[MITMapPlaceImageViewAngleKey] = self.viewAngle;
    }
    
    if (self.contents) {
        dictionary[MITMapPlaceContentsKey] = self.contents;
    }
    
    if (self.snippets) {
        dictionary[MITMapPlaceSnippetsKey] = self.snippets;
    }

    if (CLLocationCoordinate2DIsValid(self.coordinate)) {
        dictionary[MITMapPlaceLatitudeCoordinateKey] = @(self.coordinate.latitude);
        dictionary[MITMapPlaceLongitudeCoordinateKey] = @(self.coordinate.longitude);
    }

    return dictionary;
}

@end
