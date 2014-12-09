#import "MITLibrariesMITLoanItem.h"

@interface MITLibrariesMITLoanItem ()
@property (copy, nonatomic) NSString *loanedAtDateString;
@property (copy, nonatomic) NSString *dueAtDateString;
@end

@implementation MITLibrariesMITLoanItem

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesMITLoanItem class]];
    NSMutableDictionary *superMappings = [[super attributeMappings] mutableCopy];
    [superMappings addEntriesFromDictionary:@{@"loaned_at" : @"loanedAtDateString",
                                             @"due_at" : @"dueAtDateString",
                                             @"overdue" : @"overdue",
                                             @"long_overdue" : @"longOverdue",
                                             @"pending_fine" : @"pendingFine",
                                             @"formatted_pending_fine" : @"formattedPendingFine",
                                             @"due_text" : @"dueText",
                                              @"has_hold" : @"hasHold"}];
    [mapping addAttributeMappingsFromDictionary:superMappings];

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
