#import <Foundation/Foundation.h>
#import "MITLibrariesAvailability.h"
#import "MITLibrariesWebservices.h"

@interface MITLibrariesHolding : NSObject <MITInitializableWithDictionaryProtocol>

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSString *library;
@property (nonatomic, strong) NSString *address;
@property (nonatomic) NSInteger count;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSArray *availability;

@end
