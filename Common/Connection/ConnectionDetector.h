#import <Foundation/Foundation.h>


@interface ConnectionDetector : NSObject {

}

+(id)sharedConnectionDetector;
+(bool)isConnected;

@end
