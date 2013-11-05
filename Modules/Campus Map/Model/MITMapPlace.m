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

static NSString* const MITMapPlaceContentsKey = @"contents";
static NSString* const MITMapPlaceURLKey = @"url";

static NSString* const MITMapPlaceSnippetsKey = @"snippets";

@implementation MITMapPlace
@synthesize coordinate = _coordinate;
@dynamic identifier;
@dynamic buildingNumber;
@dynamic architect;
@dynamic name;
@dynamic mailingAddress;
@dynamic city;
@dynamic imageCaption;
@dynamic imageURL;
@dynamic streetAddress;
@dynamic longitude;
@dynamic latitude;
@dynamic url;
@dynamic contents;
@dynamic building;
@dynamic bookmark;

- (id)init
{
    self = [super init];
    if (self) {
        _coordinate = kCLLocationCoordinate2DInvalid;
    }

    return self;
}

- (void)performUpdate:(NSDictionary*)placeDictionary
{
    self.architect = placeDictionary[MITMapPlaceArchitectKey];

    NSString *buildingNumber = placeDictionary[MITMapPlaceBuildingNumberKey];
    if ([buildingNumber length]) {
        self.buildingNumber = buildingNumber;
    }

    self.city = placeDictionary[MITMapPlaceCityKey];
    self.identifier = placeDictionary[MITMapPlaceIdentifierKey];
    self.imageURL = placeDictionary[MITMapPlaceImageURLKey];
    self.mailingAddress = placeDictionary[MITMapPlaceMailingAddressKey];
    self.name = placeDictionary[MITMapPlaceNameKey];
    self.streetAddress = placeDictionary[MITMapPlaceStreetAddressKey];
    self.imageCaption = [NSString stringWithFormat:@"View from %@",placeDictionary[MITMapPlaceImageViewAngleKey]];
    self.url = placeDictionary[MITMapPlaceURLKey];


    if (placeDictionary[MITMapPlaceLatitudeCoordinateKey] && placeDictionary[MITMapPlaceLongitudeCoordinateKey]) {
        self.latitude = @([placeDictionary[MITMapPlaceLatitudeCoordinateKey] doubleValue]);
        self.longitude = @([placeDictionary[MITMapPlaceLongitudeCoordinateKey] doubleValue]);
    } else {
        self.latitude = @(kCLLocationCoordinate2DInvalid.latitude);
        self.latitude = @(kCLLocationCoordinate2DInvalid.longitude);
    }
    
    NSManagedObjectContext *context = self.managedObjectContext;
    if (placeDictionary[MITMapPlaceContentsKey]) {
        for (MITMapPlace *oldContent in self.contents) {
            [context deleteObject:oldContent];
        }

        NSArray *contents = placeDictionary[MITMapPlaceContentsKey];
        if (![[NSNull null] isEqual:contents]) {
            for (NSDictionary *placeContent in contents) {
                MITMapPlace *place = [NSEntityDescription insertNewObjectForEntityForName:@"MapPlace" inManagedObjectContext:context];
                [place performUpdate:placeContent];
                place.building = self;
            }
        }
    }
}

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
}


#pragma mark - Protocols
#pragma mark MKAnnotation
// Shared between MGSAnnotation and MKAnnotation protocols
- (NSString*)title
{
    if ([self.buildingNumber length]) {
        return [NSString stringWithFormat:@"Building %@", self.buildingNumber];
    } else {
        return self.name;
    }
}

- (NSString*)subtitle
{
    if (![self.name isEqualToString:self.title]) {
        return self.name;
    } else {
        return nil;
    }
}


#pragma mark MGSAnnotation
- (NSString*)detail
{
    return [self subtitle];
}

@end
