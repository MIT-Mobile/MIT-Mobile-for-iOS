#import <Foundation/Foundation.h>

@interface MITLibrariesLink : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *url;

@end