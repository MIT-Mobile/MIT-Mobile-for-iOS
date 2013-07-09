#import "ModuleVersions.h"
#import "MobileRequestOperation.h"

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
    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithRelativePath:@"apis/apps/timestamps" parameters:nil] autorelease];
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
+ (ModuleVersions*)sharedVersions {
    static ModuleVersions *_sharedVersions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedVersions = [[self alloc] init];
    });
    
    return _sharedVersions;
}
@end
