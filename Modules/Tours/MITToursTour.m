#import "MITToursTour.h"
#import "MITToursLink.h"
#import "MITToursStop.h"
#import "CoreLocation+MITAdditions.h"

static NSString *const kMITToursMainLoop = @"Main Loop";
static NSString *const kMITToursSideTrip = @"Side Trip";

@implementation MITToursTour

@dynamic identifier;
@dynamic url;
@dynamic title;
@dynamic shortTourDescription;
@dynamic lengthInKM;
@dynamic descriptionHTML;
@dynamic estimatedDurationInMinutes;
@dynamic links;
@dynamic stops;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                  @"short_description" : @"shortTourDescription",
                                                  @"length_in_km" : @"lengthInKM",
                                                  @"description_html" : @"descriptionHTML",
                                                  @"estimated_duration_in_minutes" : @"estimatedDurationInMinutes"}];
    
    [mapping addAttributeMappingsFromArray:@[@"title", @"url"]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"links" toKeyPath:@"links" withMapping:[MITToursLink objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"stops" toKeyPath:@"stops" withMapping:[MITToursStop objectMapping]]];
    
    return mapping;
}

- (NSArray *)mainLoopStops
{
    return [self stopsForType:kMITToursMainLoop];
}

- (NSArray *)sideTripsStops
{
    return [self stopsForType:kMITToursSideTrip];
}

- (NSArray *)stopsForType:(NSString *)type
{
    NSMutableArray *stops = [[NSMutableArray alloc] init];
    for (MITToursStop *stop in self.stops) {
        if ([stop.stopType isEqualToString:type]) {
            [stops addObject:stop];
        }
    }
    return stops;
}

- (NSString *)durationString
{
    NSInteger hours = [self.estimatedDurationInMinutes integerValue] / 60;
    NSInteger minutes = [self.estimatedDurationInMinutes integerValue] % 60;
    
    NSString *hoursString = (hours > 0) ? [NSString stringWithFormat:@"%d hour%@ ", hours, (hours != 1) ? @"s" : @""] : @"";
    NSString *minutesString = (minutes > 0) ? [NSString stringWithFormat:@"%@%d minute%@", hoursString.length > 0 ? @"and " : @"", minutes, (minutes != 1) ? @"s" : @""] : @"";

    return [hoursString stringByAppendingString:minutesString];
}

- (NSString *)localizedLengthString
{
    NSLocale *locale = [NSLocale currentLocale];
    
    CGFloat kilometers = [self.lengthInKM floatValue];
    CGFloat miles = kilometers / KILOMETERS_PER_MILE;
    
    BOOL systemIsMetric = [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue];
    
    if (systemIsMetric){
        return [NSString stringWithFormat:@"%.2g km (%.2g miles)", kilometers, miles];
    }
    else {
        return [NSString stringWithFormat:@"%.2g miles (%.2g km)", miles, kilometers];
    }
}

@end
