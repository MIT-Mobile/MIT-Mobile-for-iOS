#import <CoreFoundation/CoreFoundation.h>
#import "MGSRouteLayer.h"
#import "MGSLayer+Protected.h"

@interface MGSRouteLayer ()
@property (nonatomic,strong) NSDictionary *routes;

@end

@implementation MGSRouteLayer
- (id)initWithName:(NSString*)name withStops:(NSArray*)stopAnnotations pathCoordinates:(NSArray*)pathCoordinates
{
    self = [super initWithName:name];
    
    if (self)
    {
        
    }
    
    return self;
}
@end
