#import "MITLibrariesWorldcatItem.h"

@implementation MITLibrariesWorldcatItem

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.identifier = dictionary[@"id"];
        self.url = dictionary[@"url"];
        self.worldCatUrl = dictionary[@"worldcat_url"];
        self.title = dictionary[@"title"];
        self.coverImages = [MITLibrariesWebservices parseJSONArray:dictionary[@"cover_images"] intoObjectsOfClass:[MITLibrariesCoverImage class]];
        self.author = dictionary[@"authors"];
        self.year = dictionary[@"years"];
        self.publisher = dictionary[@"publishers"];
        self.format = dictionary[@"formats"];
        self.isbns = dictionary[@"isbns"];
        self.subject = dictionary[@"subjects"];
        self.language = dictionary[@"langs"];
        self.extent = dictionary[@"extents"];
        self.summaries = dictionary[@"summaries"];
        self.editions = dictionary[@"editions"];
        self.address = dictionary[@"address"];
        self.holdings = [MITLibrariesWebservices parseJSONArray:dictionary[@"holdings"] intoObjectsOfClass:[MITLibrariesHolding class]];
        self.citations = [self parseCitations:dictionary[@"citations"]];
        self.composedHTML = dictionary[@"composed-html"];
    }
    return self;
}

- (NSArray *)parseCitations:(NSDictionary *)JSONCitations
{
    if (!JSONCitations) {
        return nil;
    }
    
    NSMutableArray *citations = [[NSMutableArray alloc] init];
    for (NSString *citationKey in [JSONCitations allKeys]) {
        MITLibrariesCitation *citation = [[MITLibrariesCitation alloc] initWithName:citationKey citation:JSONCitations[citationKey]];
        [citations addObject:citation];
    }
    return citations;
}

- (NSString *)yearsString
{
    if (self.year.count <= 0) {
        return nil;
    } else {
        return self.year[0];
    }
}

- (NSString *)authorsString
{
    if (self.author.count <= 0) {
        return nil;
    }
    
    NSMutableString *authorsString = [NSMutableString stringWithString:self.author[0]];
    
    for (NSInteger i = 1; i < self.author.count; i++) {
        [authorsString appendString:@", "];
        [authorsString appendString:self.author[i]];
    }
    
    return [NSString stringWithString:authorsString];
}

@end
