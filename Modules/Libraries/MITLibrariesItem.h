#import <Foundation/Foundation.h>

@interface MITLibrariesItem : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *imageUrl;
@property (nonatomic, strong) NSArray *author;
@property (nonatomic, strong) NSArray *year;
@property (nonatomic, strong) NSArray *publisher;

@end
