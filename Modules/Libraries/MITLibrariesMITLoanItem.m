#import "MITLibrariesMITLoanItem.h"

@implementation MITLibrariesMITLoanItem

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super initWithDictionary:dictionary];
    if (self) {
        self.loanedAt = [[MITLibrariesWebservices librariesDateFormatter] dateFromString:dictionary[@"loaned_at"]];
        self.dueAt = [[MITLibrariesWebservices librariesDateFormatter] dateFromString:dictionary[@"due_at"]];
        self.overdue = [dictionary[@"overdue"] boolValue];
        self.longOverdue = [dictionary[@"long_overdue"] boolValue];
        self.pendingFine = [dictionary[@"pending_fine"] integerValue];
        self.dueText = dictionary[@"due_text"];
        self.hasHold = [dictionary[@"has_hold"] boolValue];
    }
    return self;
}

@end