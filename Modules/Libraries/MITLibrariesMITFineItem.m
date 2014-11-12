#import "MITLibrariesMITFineItem.h"

@interface MITLibrariesMITFineItem ()
@property (nonatomic, copy) NSString *finedAtDateString;
@end

@implementation MITLibrariesMITFineItem

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesMITFineItem class]];
    NSDictionary *superMappings = [super attributeMappings];
    NSMutableDictionary *attributeMappings = [NSMutableDictionary dictionaryWithDictionary:superMappings];
    attributeMappings[@"status"] = @"status";
    attributeMappings[@"description"] = @"fineDescription";
    attributeMappings[@"formatted_amount"] = @"formattedAmount";
    attributeMappings[@"amount"] = @"amount";
    attributeMappings[@"fined_at"] = @"finedAtDateString";
    [mapping addAttributeMappingsFromDictionary:attributeMappings];
    
    for (RKRelationshipMapping *relationshipMapping in [super relationshipMappings]) {
        [mapping addPropertyMapping:relationshipMapping];
    }
    
    return mapping;
}

#pragma mark - Getters

- (NSDate *)finedAtDate
{
    return [[MITLibrariesWebservices librariesDateFormatter] dateFromString:self.finedAtDateString];
}

@end
