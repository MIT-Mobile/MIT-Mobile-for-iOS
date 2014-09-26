#import <Foundation/Foundation.h>
#import "MITInitializableWithDictionaryProtocol.h"

@interface MITLibrariesAvailability : NSObject <MITInitializableWithDictionaryProtocol>

@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *collection;
@property (nonatomic, strong) NSString *callNumber;
@property (nonatomic, strong) NSString *status;
@property (nonatomic) BOOL available;

@end
