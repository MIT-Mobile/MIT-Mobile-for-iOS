#import "ModuleVersions.h"
//#import "MITTouchstoneRequestOperation+MITMobileV2.h"

@interface ModuleVersions ()
@property (nonatomic,strong) NSDictionary *moduleDates;
@end

@implementation ModuleVersions
- (id)init {
    self = [super init];

    if (self) {
        self.moduleDates = nil;
    }

    return self;
}

#pragma mark - Public Methods
- (BOOL)isDataAvailable {
    return (self.moduleDates != nil);
}

- (void)updateVersionInformation {
//    NSURLRequest *request = [NSURLRequest requestForModule:@"version" command:@"list" parameters:nil];
//    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
//
//    __weak ModuleVersions *weakSelf = self;
//    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSDictionary *moduleVersionResponse) {
//        ModuleVersions *blockSelf = weakSelf;
//        if (!blockSelf) {
//            return;
//        } else if (![moduleVersionResponse isKindOfClass:[NSDictionary class]]) {
//            DDLogError(@"invalid response for %@: result is kind of %@, expected %@", request.URL.path, NSStringFromClass([moduleVersionResponse class]), NSStringFromClass([NSDictionary class]));
//        } else {
//            NSMutableDictionary *moduleDates = [[NSMutableDictionary alloc] init];
//            [moduleVersionResponse enumerateKeysAndObjectsUsingBlock:^(NSString *moduleName, NSDictionary *dateInformation, BOOL *stop) {
//                NSAssert([moduleName isKindOfClass:[NSString class]], @"module name is kind of %@, expected %@", NSStringFromClass([moduleName class]),NSStringFromClass([NSString class]));
//                NSAssert([dateInformation isKindOfClass:[NSDictionary class]], @"date information is kind of %@, expected %@", NSStringFromClass([dateInformation class]),NSStringFromClass([NSDictionary class]));
//
//                NSMutableDictionary *datesForModule = [[NSMutableDictionary alloc] init];
//                [dateInformation enumerateKeysAndObjectsUsingBlock:^(NSString *fieldName, NSString *timestampString, BOOL *stop) {
//                    NSTimeInterval timestamp = [timestampString doubleValue];
//                    datesForModule[fieldName] = [NSDate dateWithTimeIntervalSince1970:timestamp];
//                }];
//
//                moduleDates[moduleName] = datesForModule;
//            }];
//
//            self.moduleDates = moduleDates;
//        }
//    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
//        ModuleVersions *blockSelf = weakSelf;
//        if (!blockSelf) {
//            return;
//        } else {
//            DDLogWarn(@"request for %@ failed: %@",request.URL.path,error);
//            self.moduleDates = nil;
//        }
//    }];
//
//    [[NSOperationQueue mainQueue] addOperation:requestOperation];
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
