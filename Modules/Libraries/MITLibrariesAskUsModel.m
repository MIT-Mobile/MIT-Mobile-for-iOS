#import "MITLibrariesAskUsModel.h"

@implementation MITLibrariesAskUsModel

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesAskUsModel class]];
    
    [mapping addAttributeMappingsFromArray:@[@"topics", @"consultationLists"]];
    
    return mapping;
}

@end
