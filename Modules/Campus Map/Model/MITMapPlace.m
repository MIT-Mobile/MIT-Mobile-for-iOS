#import <MapKit/MapKit.h>
#import "MITMapPlace.h"
#import "MITAdditions.h"
#import "MITMapSearch.h"
#import "MITMapCategory.h"

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
@dynamic coordinate;
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
@dynamic categoryIds;
@dynamic categories;
@dynamic contents;
@dynamic bookmark;
@dynamic search;

- (id)init
{
    self = [super init];
    if (self) {
        
    }

    return self;
}

#pragma mark MKAnnotation

- (NSString*)title
{
    if ([self.buildingNumber length] > 0) {
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

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
}

@end
