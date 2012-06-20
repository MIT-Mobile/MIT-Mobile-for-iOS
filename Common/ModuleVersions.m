#import "ModuleVersions.h"
#import "MobileRequestOperation.h"

static ModuleVersions *_sharedVersions = nil;

@interface ModuleVersions ()
@property (nonatomic,retain) NSDictionary *moduleDates;
@end

@implementation ModuleVersions
@synthesize moduleDates = _moduleDates;

- (id)init {
    self = [super init];

    if (self) {
        self.moduleDates = nil;
    }

    return self;
}

- (void)dealloc {
    self.moduleDates = nil;
    [super dealloc];
}

#pragma mark - Public Methods
- (BOOL)isDataAvailable {
    return (self.moduleDates != nil);
}

- (void)updateVersionInformation {
    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithModule:@"version"
                                                                              command:@"list"
                                                                           parameters:nil] autorelease];
    
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (!error) {
            NSDictionary *remoteDates = (NSDictionary *)jsonResult;
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
    };

    [[NSOperationQueue mainQueue] addOperation:request];
}

- (NSDictionary *)lastUpdateDatesForModule:(NSString *)module {
    NSDictionary *moduleInfo = [self.moduleDates objectForKey:module];

    if (moduleInfo != nil) {
        return [NSDictionary dictionaryWithDictionary:moduleInfo];
    } else {
        return nil;
    }
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
