#import "MITLibrariesMITItem.h"

@implementation MITLibrariesMITItem

+ (NSDictionary *)attributeMappings
{
    return @{@"call_number" : @"callNumber",
             @"author" : @"author",
             @"year" : @"year",
             @"title" : @"title",
             @"imprint" : @"imprint",
             @"isbn" : @"isbn",
             @"doc_number" : @"docNumber",
             @"material" : @"material",
             @"sub_library" : @"subLibrary",
             @"barcode" : @"barcode"};

}

+ (NSArray *)relationshipMappings
{
    NSMutableArray *relationshipMappings = [NSMutableArray array];
    RKRelationshipMapping *coverImagesRelationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"cover_images" toKeyPath:@"coverImages" withMapping:[MITLibrariesCoverImage objectMapping]];
    [relationshipMappings addObject:coverImagesRelationshipMapping];
    return relationshipMappings;
}

@end
