#import "MITLibrariesMITItem.h"
#import "MITInitializableWithDictionaryProtocol.h"
#import "MITMappedObject.h"

@interface MITLibrariesMITHoldItem : MITLibrariesMITItem <MITInitializableWithDictionaryProtocol, MITMappedObject>

@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *pickupLocation;
@property (nonatomic) BOOL readyForPickup;

@end
