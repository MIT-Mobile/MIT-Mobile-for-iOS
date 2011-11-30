#import "WorldCatBook.h"

NSString * const MITLibrariesOCLCCode = @"MYG";

static NSString * const WCHoldingStatusKey = @"status";
static NSString * const WCHoldingLocationKey = @"location";
static NSString * const WCHoldingCallNumberKey = @"call-no";



@interface WorldCatBook (Private)

- (NSArray *)arrayOfStringsFromDict:(NSDictionary *)dict key:(NSString *)key;
- (NSString *)stringFromDict:(NSDictionary *)dict key:(NSString *)key;

@end

@interface WorldCatHolding ()
@property (nonatomic,retain) NSDictionary *libraryAvailability;
@end

@implementation WorldCatHolding
@synthesize address;
@synthesize url;
@synthesize library;
@synthesize code;
@synthesize count;
@synthesize availability = _availability;
@synthesize libraryAvailability = _libraryAvailability;

- (void)dealloc {
    self.address = nil;
    self.url = nil;
    self.library = nil;
    self.code = nil;
    self.availability = nil;
    [super dealloc];
}

- (void)setAvailability:(NSArray *)availability {
    if (availability != _availability) {
        [_availability release];
        _availability = nil;
    }
    
    NSIndexSet *goodIndexes = [availability indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = obj;
            if ([[dict objectForKey:WCHoldingLocationKey] isKindOfClass:[NSString class]] &&
                [[dict objectForKey:WCHoldingCallNumberKey] isKindOfClass:[NSString class]] &&
                [[dict objectForKey:WCHoldingStatusKey] isKindOfClass:[NSString class]]) {
                return YES;
            }
        }
        return NO;
    }];
    
    _availability = [[availability objectsAtIndexes:goodIndexes] retain];
}

- (NSDictionary*)libraryAvailability
{
    if (_libraryAvailability == nil)
    {
        NSMutableDictionary *availability = [NSMutableDictionary dictionary];
        [self.availability enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *book = (NSDictionary*)obj;
            NSString *location = [book objectForKey:WCHoldingLocationKey];
            NSMutableArray *array = [availability objectForKey:location];
            
            if (array == nil)
            {
                array = [NSMutableArray array];
                [availability setObject:array
                                 forKey:location];
            }
            
            [array addObject:book];
        }];
        
        [self setLibraryAvailability:availability];
    }
    
    return _libraryAvailability;
}

- (NSUInteger)inLibraryCountForLocation:(NSString*)location
{
    location = [location lowercaseString];
    
    NSIndexSet *set = [self.availability indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *dict = (NSDictionary*)obj;
        NSString *bookLocation = [[dict objectForKey:WCHoldingLocationKey] lowercaseString];
        
        if ([bookLocation isEqualToString:location])
        {
            NSString *status = [obj valueForKey:WCHoldingStatusKey];
            NSRange range = [status rangeOfString:@"In Library"
                                          options:NSCaseInsensitiveSearch];
            
            return (([status length] > 0) && (range.location != NSNotFound));
        }
        
        return NO;
    }];
                           
    return [set count];
}

- (NSUInteger)inLibraryCount {
    NSIndexSet *indexes = [self.availability indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSString *status = [obj valueForKey:WCHoldingStatusKey];
        NSRange range = [status rangeOfString:@"In Library" options:NSCaseInsensitiveSearch];
        if ([status length] > 0 && range.location == 0) {
            return YES;
        } else {
            return NO;
        }
    }];
    return [indexes count];
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

@synthesize formats;
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
    self.formats = nil;
    self.addresses = nil;
    self.extents = nil;
    self.holdings = nil;
    self.lang = nil;
    self.subjects = nil;
    self.summarys = nil;
    [super dealloc];
}

- (void)updateDetailsWithDictionary:(NSDictionary *)dict {
    self.formats = [self arrayOfStringsFromDict:dict key:@"format"];
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
        if ([holdingDict objectForKey:@"url"]) {
            holding.url = [self stringFromDict:holdingDict key:@"url"];
        }
        holding.code = [self stringFromDict:holdingDict key:@"code"];
        id countObj = [holdingDict objectForKey:@"count"];
        if ([countObj isKindOfClass:[NSNumber class]]) {
            holding.count = [countObj unsignedIntegerValue];
        }
        holding.availability = [holdingDict objectForKey:@"availability"];
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
                WLog(@"key %@ has invalid data format",key);
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
        WLog(@"key %@ key not string", key);
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
