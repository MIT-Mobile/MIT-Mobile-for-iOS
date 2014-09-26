#import "MITLibrariesMITItem.h"
#import "MITInitializableWithDictionaryProtocol.h"

@interface MITLibrariesMITHoldItem : MITLibrariesMITItem <MITInitializableWithDictionaryProtocol>

@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *pickupLocation;

@end
