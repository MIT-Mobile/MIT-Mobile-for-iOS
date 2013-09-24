#import <Foundation/Foundation.h>

@interface ModuleVersions : NSObject {
    NSDictionary *_moduleDates;
}

@property (nonatomic, readonly, retain) NSDictionary *moduleDates;
+ (ModuleVersions*)sharedVersions;

- (id)init;
- (void)dealloc;

- (BOOL)isDataAvailable;
- (void)updateVersionInformation;
- (NSDictionary *)lastUpdateDatesForModule:(NSString *)module;
@end
