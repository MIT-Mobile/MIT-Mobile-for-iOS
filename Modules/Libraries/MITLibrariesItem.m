#import "MITLibrariesItem.h"

@implementation MITLibrariesItem

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.identifier = dictionary[@"id"];
        self.url = dictionary[@"url"];
        self.title = dictionary[@"title"];
        self.imageUrl = dictionary[@"image"];
        self.author = dictionary[@"author"];
        self.year = dictionary[@"year"];
        self.publisher = dictionary[@"publisher"];
        self.format = dictionary[@"format"];
        self.subject = dictionary[@"subject"];
        self.language = dictionary[@"lang"];
        self.extent = dictionary[@"extent"];
        self.address = dictionary[@"address"];
        self.holdings = [self parseHoldings:dictionary[@"holdings"]];
        self.citations = [self parseCitations:dictionary[@"citations"]];
        self.composedHTML = dictionary[@"composed-html"];
    }
    return self;
}

- (NSArray *)parseHoldings:(NSArray *)JSONHoldings
{
    if (!JSONHoldings) {
        return nil;
    }
    
    NSMutableArray *holdings = [[NSMutableArray alloc] init];
    for (NSDictionary *holdingDictionary in JSONHoldings) {
        MITLibrariesHolding *holding = [[MITLibrariesHolding alloc] initWithDictionary:holdingDictionary];
        [holdings addObject:holding];
    }
    return holdings;
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

@end
