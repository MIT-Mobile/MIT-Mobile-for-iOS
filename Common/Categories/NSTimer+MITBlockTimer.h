#import <Foundation/Foundation.h>

/** Adds methods to create an NSTimer using a block instead of a
 target/selector pair.
 */
@interface NSTimer (MITBlockTimer)

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds repeats:(BOOL)repeats fired:(void (^)(void))firedBlock;
+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)seconds repeats:(BOOL)repeats fired:(void (^)(void))firedBlock;
@end