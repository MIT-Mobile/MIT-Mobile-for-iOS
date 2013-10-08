#import "MITMapSearchResultAnnotation.h"
#import "UIKit+MITAdditions.h"
#import "MITMapPlace.h"

@implementation MITMapSearchResultAnnotation
- (id)initWithPlace:(MITMapPlace *)place
{
    self = [super init];
    if (self) {
        _place = place;
    }

    return self;
}

- (NSDictionary*)info
{
	return [self.place dictionaryValue];
}

#pragma mark MKAnnotation
- (NSString*)title
{
    if (self.place.buildingNumber) {
        return [NSString stringWithFormat:@"Building %@", self.place.buildingNumber];
    } else {
        return self.place.name;
    }
}

- (NSString*)subtitle
{
    if (![self.place.name isEqualToString:self.title]) {
        return self.place.name;
    } else {
        return nil;
    }
}

- (CLLocationCoordinate2D)coordinate
{
    return self.place.coordinate;
}

@end
