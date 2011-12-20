#import <Foundation/Foundation.h>

@class Reachability;

@interface ConnectionDetector : NSObject {

}

@property (retain) Reachability *reachability;

+(id)sharedConnectionDetector;
+(BOOL)isConnected;

@end
