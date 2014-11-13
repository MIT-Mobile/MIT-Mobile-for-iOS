#import "MITLibrariesMITFineItem.h"

@interface MITLibrariesMITFineItem ()
@property (nonatomic, copy) NSString *finedAtDateString;
@end

@implementation MITLibrariesMITFineItem

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesMITFineItem class]];
    NSMutableDictionary *superMappings = [[super attributeMappings] mutableCopy];
    [superMappings addEntriesFromDictionary:@{@"status" : @"status",
                                              @"description" : @"fineDescription",
                                              @"formatted_amount" : @"formattedAmount",
                                              @"amount" : @"amount",
                                              @"fined_at" : @"finedAtDateString"}];
    [mapping addAttributeMappingsFromDictionary:superMappings];
    
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
