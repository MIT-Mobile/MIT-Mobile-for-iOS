#import "MITLibrariesMITItem.h"
#import "MITLibrariesWebservices.h"
#import "MITMappedObject.h"

@interface MITLibrariesMITLoanItem : MITLibrariesMITItem <MITInitializableWithDictionaryProtocol, MITMappedObject>

@property (nonatomic, readonly) NSDate *loanedAt;
@property (nonatomic, readonly) NSDate *dueAt;
@property (nonatomic) BOOL overdue;
@property (nonatomic) BOOL longOverdue;
@property (nonatomic) NSInteger pendingFine;
@property (nonatomic, strong) NSString *formattedPendingFine;
@property (nonatomic, strong) NSString *dueText;
@property (nonatomic) BOOL hasHold;

@end
