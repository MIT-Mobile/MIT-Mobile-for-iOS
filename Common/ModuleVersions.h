#import <Foundation/Foundation.h>
#import "MITMobileWebAPI.h"

@interface ModuleVersions : NSObject <JSONLoadedDelegate> {
    NSDictionary *_moduleDates;
    MITMobileWebAPI *_apiRequest;
}

@property (nonatomic, readonly, retain) NSDictionary *moduleDates;
+ (ModuleVersions*)sharedVersions;

- (id)init;
- (void)dealloc;

- (BOOL)isDataAvailable;
- (void)updateVersionInformation;
- (NSDictionary *)lastUpdateDatesForModule:(NSString *)module;
@end
