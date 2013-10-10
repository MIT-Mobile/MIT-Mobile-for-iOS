#import "MapSearch.h"

@implementation MapSearch
@dynamic searchTerm;
@dynamic date;

- (NSString*)normalizedSearchTerm
{
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    return [[self.searchTerm componentsSeparatedByCharactersInSet:whitespaceSet] componentsJoinedByString:@""];
}

@end
