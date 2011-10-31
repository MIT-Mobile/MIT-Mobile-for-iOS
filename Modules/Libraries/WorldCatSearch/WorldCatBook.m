#import "WorldCatBook.h"


@interface WorldCatBook (Private)

- (NSArray *)arrayOfStringsFromDict:(NSDictionary *)dict key:(NSString *)key;
- (NSString *)stringFromDict:(NSDictionary *)dict key:(NSString *)key;

@end

@implementation WorldCatHolding
@synthesize address;
@synthesize url;
@synthesize library;
@synthesize code;
@synthesize count;

- (void)dealloc {
    self.address = nil;
    self.url = nil;
    self.library = nil;
    self.code = nil;
    [super dealloc];
}

@end

@implementation WorldCatBook
@synthesize identifier;
@synthesize title;
@synthesize imageURL;
@synthesize isbns;
@synthesize publishers;
@synthesize years;
@synthesize authors;

@synthesize addresses;
@synthesize extents;
@synthesize holdings;
@synthesize lang;
@synthesize subjects;
@synthesize summarys;
@synthesize editions;

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

- (void)dealloc {
    self.identifier = nil;
    self.title = nil;
    self.imageURL = nil;
    self.authors = nil;
    self.publishers = nil;
    self.years = nil;
    self.isbns = nil;
    
    // detail fields
    self.addresses = nil;
    self.extents = nil;
    self.holdings = nil;
    self.lang = nil;
    self.subjects = nil;
    self.summarys = nil;
    [super dealloc];
}

- (void)updateDetailsWithDictionary:(NSDictionary *)dict {
    self.addresses = [self arrayOfStringsFromDict:dict key:@"address"];
    self.extents = [self arrayOfStringsFromDict:dict key:@"extent"];
    self.lang = [self arrayOfStringsFromDict:dict key:@"lang"];
    self.subjects = [self arrayOfStringsFromDict:dict key:@"subject"];
    self.summarys = [self arrayOfStringsFromDict:dict key:@"summary"];
    self.editions = [self arrayOfStringsFromDict:dict key:@"edition"];
    
    NSMutableDictionary *tempHoldings = [NSMutableDictionary dictionary];
    for (NSDictionary *holdingDict in [dict objectForKey:@"holdings"]) {
        WorldCatHolding *holding = [[[WorldCatHolding alloc] init] autorelease];
        holding.address = [self stringFromDict:holdingDict key:@"address"];
        holding.library = [self stringFromDict:holdingDict key:@"library"];
        holding.url = [self stringFromDict:holdingDict key:@"url"];
        holding.code = [self stringFromDict:holdingDict key:@"code"];
        id countObj = [holdingDict objectForKey:@"count"];
        if ([countObj isKindOfClass:[NSNumber class]]) {
            holding.count = [countObj unsignedIntegerValue];
        }
        [tempHoldings setObject:holding forKey:holding.code];
    }
    self.holdings = tempHoldings;
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

- (NSString *)authorYear {
    NSString *authorYear = @"";
    if (self.years.count > 0) {
        authorYear = [NSString stringWithFormat:@"%@; ", [self.years objectAtIndex:0]];
    }
    
    NSString *authorsString = [self.authors componentsJoinedByString:@" "];
    return [authorYear stringByAppendingString:authorsString];
}

- (NSString *)isbn {
    if (self.isbns.count >= 2) {
        return [self.isbns objectAtIndex:1];
    }
    return nil;
}
@end
