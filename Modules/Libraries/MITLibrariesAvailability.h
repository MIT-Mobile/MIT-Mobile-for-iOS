#import <Foundation/Foundation.h>

@interface MITLibrariesAvailability : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *collection;
@property (nonatomic, strong) NSString *callNumber;
@property (nonatomic, strong) NSString *status;
@property (nonatomic) BOOL available;

@end
