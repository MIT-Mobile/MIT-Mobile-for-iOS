#import "MITDiningPlace.h"
#import "MITDiningRetailVenue.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningLocation.h"

@implementation MITDiningPlace

- (instancetype)initWithRetailVenue:(MITDiningRetailVenue *)retailVenue
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
- (instancetype)initWithHouseVenue:(MITDiningHouseVenue *)houseVenue
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

- (BOOL)setCoordinateWithVenueLocation:(MITDiningLocation *)venueLocation
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
        titleToReturn = self.houseVenue.name;
    } else if (self.retailVenue) {
        titleToReturn = self.retailVenue.name;
    }
    return titleToReturn;
}
@end