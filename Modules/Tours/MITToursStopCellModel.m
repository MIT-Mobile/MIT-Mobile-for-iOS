#import "MITToursStopCellModel.h"
#import "CoreLocation+MITAdditions.h"
#import "MITToursDirectionsToStop.h"
#import "MITLocationManager.h"

@implementation MITToursStopCellModel

- (instancetype)initWithStop:(MITToursStop *)stop
                   stopIndex:(NSInteger)stopIndex
{
    self = [super init];
    if (self) {
        self.stop = stop;
        self.stopIndex = stopIndex;
    }
    return self;
}

- (NSString *)titleText
{
    return [NSString stringWithFormat:@"%d. %@", self.stopIndex + 1, self.stop.title];
}

- (NSString *)distanceText
{
    if ([MITLocationManager locationServicesAuthorized]) {
        CLLocation *currentLocation = [[MITLocationManager sharedManager] currentLocation];
        
        CLLocationDistance distance = [currentLocation distanceFromLocation:self.stop.locationForStop];
       
        double kilometers = (distance / 1000.0);
        double miles = kilometers / KILOMETERS_PER_MILE;
        
        CLLocationSmootsDistance smoots = [CLLocation smootsForDistance:distance];
        
        NSLocale *locale = [NSLocale currentLocale];
        BOOL systemIsMetric = [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue];
        
        if (systemIsMetric){
            return [NSString stringWithFormat:@"%.2f km (%.2f Smoots)", kilometers, smoots];
        }
        else {
            return [NSString stringWithFormat:@"%.2f miles (%.2f Smoots)", miles, smoots];
        }
    }
    return nil;
}


@end
