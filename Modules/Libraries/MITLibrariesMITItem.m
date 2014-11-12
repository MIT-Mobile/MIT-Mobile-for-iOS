#import "MITLibrariesMITItem.h"

@implementation MITLibrariesMITItem

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.callNumber = dictionary[@"call_number"];
        self.author = dictionary[@"author"];
        self.year = dictionary[@"year"];
        self.title = dictionary[@"title"];
        self.imprint = dictionary[@"imprint"];
        self.isbn = dictionary[@"isbn"];
        self.docNumber = dictionary[@"doc_number"];
        self.material = dictionary[@"material"];
        self.subLibrary = dictionary[@"sub_library"];
        self.barcode = dictionary[@"barcode"];
        self.coverImages = [MITLibrariesWebservices parseJSONArray:dictionary[@"cover_images"]
                                                intoObjectsOfClass:[MITLibrariesCoverImage class]];
    }
    return self;
}

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
