#import "MITToursStopAnnotation.h"

@interface MITToursStopAnnotation ()

@property (nonatomic, strong, readwrite) MITToursStop *stop;
@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, readwrite, copy) NSString *title;

@end

@implementation MITToursStopAnnotation

- (instancetype)initWithStop:(MITToursStop *)stop
{
    self = [super init];
    if (self) {
        self.stop = stop;
        self.title = stop.title;
        
        // TODO: Consider moving this coordinate mapping logic down into the CoreData / RestKit mapping layer
        NSArray *coords = (NSArray *)stop.coordinates;
        CLLocationDegrees longitude = [((NSNumber *)coords[0]) floatValue];
        CLLocationDegrees latitude = [((NSNumber *)coords[1]) floatValue];
        self.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    }
    return self;
}

@end
