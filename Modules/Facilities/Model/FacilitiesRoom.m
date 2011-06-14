#import "FacilitiesRoom.h"
#import "FacilitiesLocation.h"

@implementation FacilitiesRoom
@dynamic floor;
@dynamic number;
@dynamic building;

- (NSString*)displayString {
    return [NSString stringWithFormat:@"%@",self.number];
}

- (NSString*)description {
    return [self displayString];
}

@end
