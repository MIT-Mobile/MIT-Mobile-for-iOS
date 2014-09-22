#import "MITLibrariesLibrary.h"
#import "MITLibrariesTerm.h"

@implementation MITLibrariesLibrary

+ (RKMapping*)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesLibrary class]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                  @"phone" : @"phoneNumber"}];
    [mapping addAttributeMappingsFromArray:@[@"url", @"name", @"location"]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"terms" mapping:[MITLibrariesTerm objectMapping]];
    
    return mapping;
}

@end
