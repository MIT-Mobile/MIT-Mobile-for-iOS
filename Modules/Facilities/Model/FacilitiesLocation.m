#import "FacilitiesLocation.h"
#import "FacilitiesContent.h"
#import "FacilitiesPropertyOwner.h"


@implementation FacilitiesLocation
@dynamic number;
@dynamic uid;
@dynamic longitude;
@dynamic latitude;
@dynamic roomsUpdated;
@dynamic name;
@dynamic isHiddenInBldgServices;
@dynamic isLeased;
@dynamic categories;
@dynamic contents;
@dynamic propertyOwner;

- (NSString*)displayString {
    NSString *string = nil;
    
    if (([self.number length] > 0) && ([self.number isEqualToString:self.name] == NO)) {
        string = [NSString stringWithFormat:@"%@ - %@", self.number, self.name];
    } else {
        string = [NSString stringWithString:self.name];
    }
    
    return string;
}
@end
