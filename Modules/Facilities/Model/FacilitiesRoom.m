#import "FacilitiesRoom.h"
#import "FacilitiesLocation.h"

@implementation FacilitiesRoom
@dynamic floor;
@dynamic number;
@dynamic building;

- (NSString*)displayString {
    return [NSString stringWithFormat:@"%@%03@",self.floor,self.number];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@-%@",self.building,[self displayString]];
}

@end
