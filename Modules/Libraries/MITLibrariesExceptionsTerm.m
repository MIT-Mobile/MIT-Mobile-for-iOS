#import "MITLibrariesExceptionsTerm.h"
#import "MITLibrariesDate.h"

@implementation MITLibrariesExceptionsTerm

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesExceptionsTerm class]];
    
    [mapping addAttributeMappingsFromArray:@[@"reason"]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"hours" mapping:[MITLibrariesDate objectMapping]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"dates" mapping:[MITLibrariesDate objectMapping]];
    
    return mapping;
}

@end
