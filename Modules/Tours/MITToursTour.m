#import "MITToursTour.h"
#import "MITToursLink.h"
#import "MITToursStop.h"

static const CGFloat kilometersPerMile = 1.60934;

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

- (NSString *)durationString
{
    NSInteger hours = [self.estimatedDurationInMinutes integerValue] / 60;
    NSInteger minutes = [self.estimatedDurationInMinutes integerValue] % 60;
    
    NSString *hoursString = (hours > 0) ? [NSString stringWithFormat:@"%d hour%@ ", hours, (hours != 1) ? @"s" : @""] : @"";
    NSString *minutesString = (minutes > 0) ? [NSString stringWithFormat:@"%d minute%@", minutes, (minutes != 1) ? @"s" : @""] : @"";

    return [hoursString stringByAppendingString:minutesString];
}

- (NSString *)localizedLengthString
{
    NSLocale *locale = [NSLocale currentLocale];
    
    CGFloat kilometers = [self.lengthInKM floatValue];
    CGFloat miles = kilometers / kilometersPerMile;
    
    BOOL systemIsMetric = [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue];
    
    if (systemIsMetric){
        return [NSString stringWithFormat:@"%.2g km (%.2g miles)", kilometers, miles];
    }
    else {
        return [NSString stringWithFormat:@"%.2g miles (%.2g km)", miles, kilometers];
    }
}

@end
