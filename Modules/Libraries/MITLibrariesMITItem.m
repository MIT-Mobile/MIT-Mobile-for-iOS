#import "MITLibrariesMITItem.h"

@implementation MITLibrariesMITItem

+ (NSDictionary *)attributeMappings
{
    NSMutableDictionary *attributeMappings = [NSMutableDictionary dictionary];
    attributeMappings[@"call_number"] = @"callNumber";
    attributeMappings[@"author"] = @"author";
    attributeMappings[@"year"] = @"year";
    attributeMappings[@"title"] = @"title";
    attributeMappings[@"imprint"] = @"imprint";
    attributeMappings[@"isbn"] = @"isbn";
    attributeMappings[@"doc_number"] = @"docNumber";
    attributeMappings[@"material"] = @"material";
    attributeMappings[@"sub_library"] = @"subLibrary";
    attributeMappings[@"barcode"] = @"barcode";
    return attributeMappings;
}

+ (NSArray *)relationshipMappings
{
    NSMutableArray *relationshipMappings = [NSMutableArray array];
    RKRelationshipMapping *coverImagesRelationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"cover_images" toKeyPath:@"coverImages" withMapping:[MITLibrariesCoverImage objectMapping]];
    [relationshipMappings addObject:coverImagesRelationshipMapping];
    return relationshipMappings;
}

@end
