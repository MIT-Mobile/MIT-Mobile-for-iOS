#import "MITLibrariesMITItem.h"
#import "MITLibrariesWebservices.h"

@interface MITLibrariesMITLoanItem : MITLibrariesMITItem <MITInitializableWithDictionaryProtocol>

@property (nonatomic, strong) NSDate *loanedAt;
@property (nonatomic, strong) NSDate *dueAt;
@property (nonatomic) BOOL overdue;
@property (nonatomic) BOOL longOverdue;
@property (nonatomic) NSInteger pendingFine;
@property (nonatomic, strong) NSString *formattedPendingFine;
@property (nonatomic, strong) NSString *dueText;
@property (nonatomic) BOOL hasHold;

@end
