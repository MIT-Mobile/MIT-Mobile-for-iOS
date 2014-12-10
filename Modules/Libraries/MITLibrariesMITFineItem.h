#import "MITLibrariesMITItem.h"
#import "MITLibrariesWebservices.h"
#import "MITMappedObject.h"

@interface MITLibrariesMITFineItem : MITLibrariesMITItem <MITMappedObject>

@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *fineDescription;
@property (nonatomic, strong) NSString *formattedAmount;
@property (nonatomic) NSInteger amount;
@property (nonatomic, readonly) NSDate *finedAtDate;

@end
