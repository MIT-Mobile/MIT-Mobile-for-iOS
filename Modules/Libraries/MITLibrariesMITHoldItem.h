#import "MITLibrariesMITItem.h"
#import "MITInitializableWithDictionaryProtocol.h"

@interface MITLibrariesMITHoldItem : MITLibrariesMITItem <MITInitializableWithDictionaryProtocol>

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *pickupLocation;

@end