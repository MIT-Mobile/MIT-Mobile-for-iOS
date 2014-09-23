#import <Foundation/Foundation.h>
#import "MITLibrariesAvailability.h"

@interface MITLibrariesHolding : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSString *library;
@property (nonatomic, strong) NSString *address;
@property (nonatomic) NSInteger count;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSArray *availability;

@end
