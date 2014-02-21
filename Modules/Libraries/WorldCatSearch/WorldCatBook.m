#import "WorldCatBook.h"

NSString * const MITLibrariesOCLCCode = @"MYG";

static NSString * const WCHoldingStatusKey = @"status";
static NSString * const WCHoldingLocationKey = @"location";
static NSString * const WCHoldingCallNumberKey = @"call-no";
static NSString * const WCHoldingAvailableKey = @"available";


@interface WorldCatBook ()
- (NSArray *)arrayOfStringsFromDict:(NSDictionary *)dict key:(NSString *)key;
- (NSString *)stringFromDict:(NSDictionary *)dict key:(NSString *)key;

@end

@interface WorldCatHolding ()
@property (nonatomic,copy) NSDictionary *libraryAvailability;
@end

@implementation WorldCatHolding
- (void)setAvailability:(NSArray *)availability {
    if (![_availability isEqual:availability]) {
        NSIndexSet *validIndexes = [availability indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = (NSDictionary*)obj;
                return ([dict[WCHoldingLocationKey] isKindOfClass:[NSString class]] &&
                        [dict[WCHoldingCallNumberKey] isKindOfClass:[NSString class]] &&
                        [dict[WCHoldingStatusKey] isKindOfClass:[NSString class]]);
            } else {
                DDLogError(@"invalid object type '%@' in WorldCat availability response", NSStringFromClass([obj class]));
                return NO;
            }
        }];
        
        _availability = [availability objectsAtIndexes:validIndexes];
    }
}

- (NSDictionary*)libraryAvailability
{
    if (!_libraryAvailability) {
        NSMutableDictionary *libraryAvailability = [NSMutableDictionary dictionary];
        
        [self.availability enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *book = (NSDictionary*)obj;
            NSString *location = book[WCHoldingLocationKey];
            NSMutableArray *locationAvailability = libraryAvailability[location];
            
            if (!locationAvailability) {
                locationAvailability = [[NSMutableArray alloc] init];
                libraryAvailability[location] = locationAvailability;
            }
            
            [locationAvailability addObject:book];
        }];
        
        self.libraryAvailability = libraryAvailability;
    }
    
    return _libraryAvailability;
}

- (NSUInteger)inLibraryCountForLocation:(NSString*)location
{
    location = [location lowercaseString];
    
    NSIndexSet *set = [self.availability indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *dict = (NSDictionary*)obj;
        NSString *bookLocation = [dict[WCHoldingLocationKey] lowercaseString];
        
        return ([dict[WCHoldingAvailableKey] boolValue] &&
                [bookLocation isEqual:location]);
    }];
                           
    return [set count];
}

- (NSUInteger)inLibraryCount {
    NSIndexSet *indexes = [self.availability indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *dict = (NSDictionary*)obj;
        return [dict[WCHoldingAvailableKey] boolValue];
    }];
    
    return [indexes count];
}

@end

@implementation WorldCatBook
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

- (void)updateDetailsWithDictionary:(NSDictionary *)dict {
    self.formats = [self arrayOfStringsFromDict:dict key:@"format"];
    self.addresses = [self arrayOfStringsFromDict:dict key:@"address"];
    self.extents = [self arrayOfStringsFromDict:dict key:@"extent"];
    self.lang = [self arrayOfStringsFromDict:dict key:@"lang"];
    self.subjects = [self arrayOfStringsFromDict:dict key:@"subject"];
    self.summarys = [self arrayOfStringsFromDict:dict key:@"summary"];
    self.editions = [self arrayOfStringsFromDict:dict key:@"edition"];
    self.emailAndCiteMessage = dict[@"composed-html"];
    self.url = dict[@"url"];
    
    NSMutableDictionary *tempHoldings = [NSMutableDictionary dictionary];
    for (NSDictionary *holdingDict in dict[@"holdings"]) {
        WorldCatHolding *holding = [[WorldCatHolding alloc] init];
        holding.address = [self stringFromDict:holdingDict key:@"address"];
        holding.library = [self stringFromDict:holdingDict key:@"library"];
        holding.collection = [self stringFromDict:holdingDict key:@"collection"];
        if (holdingDict[@"url"]) {
            holding.url = [self stringFromDict:holdingDict key:@"url"];
        }
        
        holding.code = [self stringFromDict:holdingDict key:@"code"];
        
        id countObj = holdingDict[@"count"];
        if ([countObj isKindOfClass:[NSNumber class]]) {
            holding.count = [countObj unsignedIntegerValue];
        }
        
        holding.availability = holdingDict[@"availability"];
        tempHoldings[holding.code] = holding;
    }
    self.holdings = tempHoldings;
}

- (NSString *)stringFromDict:(NSDictionary *)dict key:(NSString *)key
{
    return [self objectFromDictionary:dict
                               forKey:key
                          typeOfClass:[NSString class]];
}

- (NSArray *)arrayOfStringsFromDict:(NSDictionary *)dict key:(NSString *)key {
    NSArray *array = [self objectFromDictionary:dict
                                         forKey:key
                                    typeOfClass:[NSArray class]];
    
    if (array) {
        NSMutableArray *resultArray = [[NSMutableArray alloc] init];
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[NSString class]]) {
                [resultArray addObject:obj];
            } else if ([obj respondsToSelector:@selector(stringValue)]) {
                [resultArray addObject:[obj stringValue]];
            } else {
                DDLogWarn(@"object at index %lu in array for key '%@' is a '%@', expected a '%@'", (unsigned long)idx, key, NSStringFromClass([obj class]), NSStringFromClass([NSString class]));
            }
        }];
        
        return resultArray;
    } else {
        return nil;
    }
}

- (id)objectFromDictionary:(NSDictionary*)dictionary
                    forKey:(NSString*)key
               typeOfClass:(Class)objectClass
{
    id object = dictionary[key];
    
    if (object) {
        if ([object isKindOfClass:objectClass]) {
            return object;
        } else {
            DDLogWarn(@"object for key '%@' is a '%@', expected a %@", key, NSStringFromClass([object class]), NSStringFromClass(objectClass));
            self.parseFailure = YES;
        }
    }
    
    return nil;
}

- (NSString *)yearWithAuthors {
    NSMutableString *yearWithAuthors = [NSMutableString string];
    if ([self.years count] > 0) {
        [yearWithAuthors appendString:self.years[0]];
    }
    if ([self.authors count] > 0) {
        [yearWithAuthors appendFormat:@"; %@", [self.authors componentsJoinedByString:@", "]];

    }
    return yearWithAuthors;
}

- (NSString *)isbn {
    if ([self.isbns count] >= 2) {
        return self.isbns[1];
    }
    
    return nil;
}

- (NSArray *)addressesWithPublishers {
    // Publishers should be displayed as Address + Publisher Name,
    // e.g. "New York : Modern Language Association of America,"
    // where address == "New York :" and publisher == " Modern Language Association of America," 

    // If the number of addresses doesn't match the number of publishers, just return publisher names as-is without addresses
    
    NSArray *rawPublishers = self.publishers;
    NSArray *rawAddresses = self.addresses;
    NSArray *output = rawPublishers;
    if ([rawPublishers count] != [rawAddresses count]) {
        DDLogWarn(@"mismatch between number of publishers and addresses for OCLC ID %@", self.identifier);
    } else {
        NSMutableArray *composedPublishers = [NSMutableArray array];
        for (NSInteger i = 0; i < [rawPublishers count]; i++) {
            NSString *address = rawAddresses[i];
            NSString *publisher = rawPublishers[i];
            [composedPublishers addObject:[NSString stringWithFormat:@"%@ %@", address, publisher]];
        }
        
        output = composedPublishers;
    }
    
    return output;
}

@end
