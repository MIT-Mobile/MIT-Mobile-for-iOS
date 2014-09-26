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

@end
