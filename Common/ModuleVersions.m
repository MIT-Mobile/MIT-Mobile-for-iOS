#import "ModuleVersions.h"
static ModuleVersions *_sharedVersions = nil;

@interface ModuleVersions ()
@property (nonatomic,retain) NSDictionary *moduleDates;
@property (nonatomic, retain) MITMobileWebAPI *apiRequest;
@end

@implementation ModuleVersions
@synthesize moduleDates = _moduleDates;
@synthesize apiRequest = _apiRequest;

- (id)init {
    self = [super init];

    if (self) {
        self.moduleDates = nil;
        self.apiRequest = nil;
    }

    return self;
}

- (void)dealloc {
    self.moduleDates = nil;
    self.apiRequest = nil;
    [super dealloc];
}

#pragma mark - Public Methods
- (BOOL)isDataAvailable {
    return (self.moduleDates != nil);
}

- (void)updateVersionInformation {
    if (self.apiRequest == nil) {
        self.apiRequest = [[[MITMobileWebAPI alloc] initWithModule:@"version"
                                                           command:@"list"
                                                        parameters:nil] autorelease];
        self.apiRequest.jsonDelegate = self;
    }

    if ([self.apiRequest isActive] == NO) {
        [self.apiRequest start];
    }
}

- (NSDictionary *)lastUpdateDatesForModule:(NSString *)module {
    NSDictionary *moduleInfo = [self.moduleDates objectForKey:module];

    if (moduleInfo != nil) {
        return [NSDictionary dictionaryWithDictionary:moduleInfo];
    } else {
        return nil;
    }
}

#pragma mark - JSONDelegate Methods
- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject {
    NSDictionary *remoteDates = (NSDictionary *)JSONObject;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    for (NSString *key in remoteDates) {
        NSDictionary *moduleDates = [remoteDates objectForKey:key];
        NSMutableDictionary *dateDict = [NSMutableDictionary dictionary];
        
        for (NSString *key in moduleDates) {
            NSString *epochString = [moduleDates objectForKey:key];
            NSTimeInterval epochTime = [epochString integerValue];
            NSDate *date = [[[NSDate alloc] initWithTimeIntervalSince1970:epochTime] autorelease];

            [dateDict setObject:date
                         forKey:key];
        }

        [dict setObject:dateDict
                  forKey:key];
    }

    self.moduleDates = dict;
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error {
    return NO;
}

#pragma mark - Singleton Implementation
+ (void)initialize {
    if (_sharedVersions == nil) {
        _sharedVersions = [[super allocWithZone:NULL] init];
    }
}

+ (ModuleVersions*)sharedVersions {
    return _sharedVersions;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedVersions] retain];
}

- (id)copyWithZone:(NSZone*)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

- (oneway void)release {
    return;
}

- (id)autorelease {
    return self;
}

@end
