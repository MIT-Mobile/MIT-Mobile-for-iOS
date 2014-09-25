#import "MITLibrariesMITItem.h"
#import "MITLibrariesWebservices.h"

@interface MITLibrariesMITFineItem : MITLibrariesMITItem <MITInitializableWithDictionaryProtocol>

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *fineDescription;
@property (nonatomic, strong) NSString *formattedAmount;
@property (nonatomic) NSInteger amount;
@property (nonatomic, strong) NSDate *finedAtDate;

@end