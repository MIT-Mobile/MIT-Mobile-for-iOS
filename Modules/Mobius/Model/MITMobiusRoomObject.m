#import "MITMobiusRoomObject.h"
#import "MITMobiusResource.h"

@implementation MITMobiusRoomObject

@dynamic roomName;
@dynamic longitude;
@dynamic latitude;
@dynamic resources;

#pragma mark MKAnnotation

- (NSString*)title
{
    return self.roomName;
}

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
}

@end
