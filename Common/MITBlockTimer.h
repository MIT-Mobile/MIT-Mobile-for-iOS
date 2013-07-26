#import <Foundation/Foundation.h>

typedef void (^MITTimerFireBlock)(NSTimer *timer);

@interface MITBlockTimer : NSObject
- (id)initWithFireBlock:(MITTimerFireBlock)firedBlock;
@end

@interface NSTimer (MITBlockTimer)
+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds repeats:(BOOL)repeats fired:(MITTimerFireBlock)firedBlock;
+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)seconds repeats:(BOOL)repeats fired:(MITTimerFireBlock)firedBlock;
@end