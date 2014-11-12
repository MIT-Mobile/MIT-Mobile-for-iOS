#import "MITLibrariesMITLoanItem.h"

@interface MITLibrariesMITLoanItem ()
@property (copy, nonatomic) NSString *loanedAtDateString;
@property (copy, nonatomic) NSString *dueAtDateString;
@end

@implementation MITLibrariesMITLoanItem

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesMITLoanItem class]];
    NSDictionary *superMappings = [super attributeMappings];
    NSMutableDictionary *attributeMappings = [NSMutableDictionary dictionaryWithDictionary:superMappings];
    attributeMappings[@"loaned_at"] = @"loanedAtDateString";
    attributeMappings[@"due_at"] = @"dueAtDateString";
    attributeMappings[@"overdue"] = @"overdue";
    attributeMappings[@"long_overdue"] = @"longOverdue";
    attributeMappings[@"pending_fine"] = @"pendingFine";
    attributeMappings[@"formatted_pending_fine"] = @"formattedPendingFine";
    attributeMappings[@"due_text"] = @"dueText";
    attributeMappings[@"has_hold"] = @"hasHold";
    [mapping addAttributeMappingsFromDictionary:attributeMappings];

    for (RKRelationshipMapping *relationshipMapping in [super relationshipMappings]) {
        [mapping addPropertyMapping:relationshipMapping];
    }
    
    return mapping;
}

#pragma mark - Getters | Setters

- (NSDate *)loanedAt
{
    return [[MITLibrariesWebservices librariesDateFormatter] dateFromString:self.loanedAtDateString];
}

- (NSDate *)dueAt
{
    return [[MITLibrariesWebservices librariesDateFormatter] dateFromString:self.dueAtDateString];
}

@end
