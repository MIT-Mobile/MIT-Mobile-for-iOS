#import <Foundation/Foundation.h>

@interface DiningData : NSObject

+ (DiningData *)sharedData;
- (void)loadDebugData;

@end
