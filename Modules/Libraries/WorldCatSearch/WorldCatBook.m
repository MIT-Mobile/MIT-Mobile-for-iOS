#import "WorldCatBook.h"


@interface WorldCatBook (Private)

- (NSArray *)arrayOfStringsFromDict:(NSDictionary *)dict key:(NSString *)key;
- (NSString *)stringFromDict:(NSDictionary *)dict key:(NSString *)key;

@end

@implementation WorldCatBook
@synthesize identifier;
@synthesize title;
@synthesize imageURL;
@synthesize isbns;
@synthesize publishers;
@synthesize years;
@synthesize authors;
@synthesize parseFailure;

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        self.identifier = [self stringFromDict:dict key:@"id"];
        self.title = [self stringFromDict:dict key:@"title"];
        self.imageURL = [self stringFromDict:dict key:@"image"];
        self.isbns = [self arrayOfStringsFromDict:dict key:@"isbn"];
        self.publishers = [self arrayOfStringsFromDict:dict key:@"publisher"];
        self.years = [self arrayOfStringsFromDict:dict key:@"year"];
        self.authors = [self arrayOfStringsFromDict:dict key:@"author"];
    }
    return self;
}

- (NSArray *)arrayOfStringsFromDict:(NSDictionary *)dict key:(NSString *)key {
    id object = [dict objectForKey:key];
    if (![object isKindOfClass:[NSArray class]]) {
        return [NSArray array];
    } else {
        NSArray *array = object;
        for (id item in array) {
            if (![item isKindOfClass:[NSString class]]) {
                NSLog(@"key %@ has invalid data format",key);
                self.parseFailure = YES;
                return nil;
            }
        }
    }
    return object;
}

- (NSString *)stringFromDict:(NSDictionary *)dict key:(NSString *)key {
    id object = [dict objectForKey:key];
    if (![object isKindOfClass:[NSString class]]) {
        NSLog(@"key %@ key not string", key);
        self.parseFailure = YES;
        return nil;
    }
    return object;
}

@end
