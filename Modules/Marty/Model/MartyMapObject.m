#import "MartyMapObject.h"
#import "MITMartyResource.h"

@implementation MartyMapObject

@dynamic roomName;
@dynamic resources;
@dynamic latitude;
@dynamic longitude;

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
