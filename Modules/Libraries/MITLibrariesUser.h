#import <Foundation/Foundation.h>
#import "MITLibrariesMITFineItem.h"
#import "MITLibrariesMITHoldItem.h"
#import "MITLibrariesMITLoanItem.h"
#import "MITMappedObject.h"

@interface MITLibrariesUser : NSObject <MITMappedObject, MITInitializableWithDictionaryProtocol>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *loans;
@property (nonatomic, strong) NSArray *holds;
@property (nonatomic, strong) NSArray *fines;
@property (nonatomic, strong) NSString *formattedBalance;
@property (nonatomic) NSInteger balance;
@property (nonatomic) NSInteger overdueItemsCount;
@property (nonatomic) NSInteger readyForPickupCount;

@end
