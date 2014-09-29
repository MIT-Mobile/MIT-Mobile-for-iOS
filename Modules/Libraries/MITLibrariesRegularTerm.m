#import "MITLibrariesRegularTerm.h"
#import "MITLibrariesDate.h"

@implementation MITLibrariesRegularTerm

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesRegularTerm class]];
    
    [mapping addAttributeMappingsFromArray:@[@"days"]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"hours" mapping:[MITLibrariesDate objectMapping]];
    
    return mapping;
}

@end
