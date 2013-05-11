#import <Foundation/Foundation.h>

@interface MGSBootstrapper : NSObject
+ (id)sharedBootstrapper;

- (id)init;
- (void)requestBootstrap:(void (^)(NSDictionary*,NSError*))resultBlock;

@end
