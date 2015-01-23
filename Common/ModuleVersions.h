#import <Foundation/Foundation.h>

@interface ModuleVersions : NSObject
@property (nonatomic, readonly, strong) NSDictionary *moduleDates;
+ (ModuleVersions*)sharedVersions;

- (id)init;

- (BOOL)isDataAvailable;
- (void)updateVersionInformation;
- (NSDictionary *)lastUpdateDatesForModule:(NSString *)module;
@end
