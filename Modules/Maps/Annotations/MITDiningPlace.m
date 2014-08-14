
#import "MITDiningPlace.h"

#import "RetailVenue.h"
#import "HouseVenue.h"
#import "VenueLocation.h"

@implementation MITDiningPlace

- (instancetype)initWithRetailVenue:(RetailVenue *)retailVenue
{
    self = [super init];
    if(self)
    {
        _retailVenue = retailVenue;
        BOOL locationIsValid = [self setCoordinateWithVenueLocation:retailVenue.location];
        if (!locationIsValid) {
            return nil;
        }
    }
    return self;
}
- (instancetype)initWithHouseVenue:(HouseVenue *)houseVenue
{
    self = [super init];
    if(self)
    {
        _houseVenue = houseVenue;
        BOOL locationIsValid = [self setCoordinateWithVenueLocation:houseVenue.location];
        if (!locationIsValid) {
            return nil;
        }
    }
    return self;
}

- (BOOL)setCoordinateWithVenueLocation:(VenueLocation *)venueLocation
{
    BOOL succeeded = NO;
    if (venueLocation.latitude && venueLocation.longitude) {
        self.coordinate = CLLocationCoordinate2DMake(venueLocation.latitude.doubleValue, venueLocation.longitude.doubleValue);
        succeeded = YES;
    }
    return succeeded;
    
}

- (NSString *)title
{
    NSString *titleToReturn = nil;
    if (self.houseVenue) {
        titleToReturn = self.houseVenue.title;
    } else if (self.retailVenue) {
        titleToReturn = self.retailVenue.title;
    }
    return titleToReturn;
}
@end
