#import "MITLibrariesMITItem.h"
#import "MITMappedObject.h"

@interface MITLibrariesMITHoldItem : MITLibrariesMITItem <MITMappedObject>

@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *pickupLocation;
@property (nonatomic) BOOL readyForPickup;

@end
