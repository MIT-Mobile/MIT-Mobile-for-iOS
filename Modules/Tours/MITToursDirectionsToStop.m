#import "MITToursDirectionsToStop.h"
#import "MITToursStop.h"

@implementation MITToursDirectionsToStop

@dynamic destinationID;
@dynamic title;
@dynamic bodyHTML;
@dynamic zoom;
@dynamic path;
@dynamic stop;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"destination_id" : @"destinationID",
                                                  @"body_html" : @"bodyHTML"}];
    [mapping addAttributeMappingsFromArray:@[@"title", @"zoom", @"path"]];
        
    return mapping;
}

@end
