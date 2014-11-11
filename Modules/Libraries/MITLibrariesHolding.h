#import <Foundation/Foundation.h>
#import "MITLibrariesAvailability.h"
#import "MITLibrariesWebservices.h"
#import "MITMappedObject.h"

@interface MITLibrariesHolding : NSObject <MITInitializableWithDictionaryProtocol, MITMappedObject>

@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSString *library;
@property (nonatomic, strong) NSString *address;
@property (nonatomic) NSInteger count;
@property (nonatomic, strong) NSString *requestUrl;
@property (nonatomic, strong) NSArray *availability;

@end
