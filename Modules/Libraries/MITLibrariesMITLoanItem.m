#import "MITLibrariesMITLoanItem.h"

@interface MITLibrariesMITLoanItem ()
@property (copy, nonatomic) NSString *loanedAtDateString;
@property (copy, nonatomic) NSString *dueAtDateString;
@end

@implementation MITLibrariesMITLoanItem

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesMITLoanItem class]];
    NSMutableDictionary *attributeMappings = [NSMutableDictionary dictionary];
    attributeMappings[@"loaned_at"] = @"loanedAtDateString";
    attributeMappings[@"due_at"] = @"dueAtDateString";
    attributeMappings[@"overdue"] = @"overdue";
    attributeMappings[@"long_overdue"] = @"longOverdue";
    attributeMappings[@"pending_fine"] = @"pendingFine";
    attributeMappings[@"formatted_pending_fine"] = @"formattedPendingFine";
    attributeMappings[@"due_text"] = @"dueText";
    attributeMappings[@"has_hold"] = @"hasHold";
    [mapping addAttributeMappingsFromDictionary:attributeMappings];
    return mapping;
}
- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super initWithDictionary:dictionary];
    if (self) {
        self.loanedAtDateString = dictionary[@"loaned_at"];
        self.dueAtDateString = dictionary[@"due_at"];
        self.overdue = [dictionary[@"overdue"] boolValue];
        self.longOverdue = [dictionary[@"long_overdue"] boolValue];
        self.pendingFine = [dictionary[@"pending_fine"] integerValue];
        self.formattedPendingFine = dictionary[@"formatted_pending_fine"];
        self.dueText = dictionary[@"due_text"];
        self.hasHold = [dictionary[@"has_hold"] boolValue];
    }
    return self;
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
