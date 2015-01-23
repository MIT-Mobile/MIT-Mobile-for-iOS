#import "MITLibrariesWorldcatItem.h"

@interface MITLibrariesWorldcatItem ()
@property (strong, nonatomic) NSDictionary *rawCitations;
@end

@implementation MITLibrariesWorldcatItem

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesWorldcatItem class]];
    [mapping addAttributeMappingsFromDictionary:@{ @"id" : @"identifier",
                                                   @"url" : @"url",
                                                   @"worldcat_url" : @"worldCatUrl",
                                                   @"title" : @"title",
                                                   @"authors" : @"author",
                                                   @"years" : @"year",
                                                   @"publishers" : @"publisher",
                                                   @"formats" : @"format",
                                                   @"isbns" : @"isbns",
                                                   @"subjects" : @"subject",
                                                   @"langs" : @"language",
                                                   @"extents" : @"extent",
                                                   @"summaries" : @"summaries",
                                                   @"editions" : @"editions",
                                                   @"address" : @"address",
                                                   @"composed-html" : @"composedHTML",
                                                   @"citations" : @"rawCitations"}];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"holdings" toKeyPath:@"holdings" withMapping:[MITLibrariesHolding objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"cover_images" toKeyPath:@"coverImages" withMapping:[MITLibrariesCoverImage objectMapping]]];
    return mapping;
}

- (NSArray *)citations
{
    return [self parseCitations:self.rawCitations];
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

- (NSString *)formatsString
{
    if (self.format.count <= 0) {
        return nil;
    }
    
    NSMutableString *formatsString = [NSMutableString stringWithString:self.format[0]];
    
    for (NSInteger i = 1; i < self.format.count; i++) {
        [formatsString appendString:@", "];
        [formatsString appendString:self.format[i]];
    }
    
    return [NSString stringWithString:formatsString];
}

- (NSString *)publishersString
{
    if (self.publisher.count <= 0) {
        return nil;
    }
    
    NSMutableString *publishersString = [NSMutableString stringWithString:self.publisher[0]];
    
    for (NSInteger i = 1; i < self.publisher.count; i++) {
        [publishersString appendString:@", "];
        [publishersString appendString:self.publisher[i]];
    }
    
    return [NSString stringWithString:publishersString];
}

- (NSString *)firstSummaryString
{
    if (self.summaries.count <= 0) {
        return nil;
    } else {
        return self.summaries[0];
    }
}

@end
