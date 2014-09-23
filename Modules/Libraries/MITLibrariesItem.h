#import <Foundation/Foundation.h>
#import "MITLibrariesHolding.h"
#import "MITLibrariesCitation.h"

@interface MITLibrariesItem : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *imageUrl;
@property (nonatomic, strong) NSArray *author;
@property (nonatomic, strong) NSArray *year;
@property (nonatomic, strong) NSArray *publisher;
@property (nonatomic, strong) NSArray *format;
@property (nonatomic, strong) NSArray *subject;
@property (nonatomic, strong) NSArray *language;
@property (nonatomic, strong) NSArray *extent;
@property (nonatomic, strong) NSArray *address;
@property (nonatomic, strong) NSArray *holdings;
@property (nonatomic, strong) NSArray *citations;
@property (nonatomic, strong) NSString *composedHTML;

@end
