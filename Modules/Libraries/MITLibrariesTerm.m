#import "MITLibrariesTerm.h"
#import "MITLibrariesDate.h"

@implementation MITLibrariesTerm

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesTerm class]];
    
    [mapping addAttributeMappingsFromArray:@[@"name"]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"dates" mapping:[MITLibrariesDate objectMapping]];
    
    return mapping;
}

@end
