#include "NSTimer+MITBlockTimer.h"
typedef void (^MITTimerFireBlock)(void);

@interface MITBlockTimer : NSObject
@property (nonatomic,weak) NSTimer *timer;
@property (nonatomic,copy) MITTimerFireBlock fireBlock;

- (id)initWithFireBlock:(MITTimerFireBlock)firedBlock;
- (void)timerFired:(NSTimer*)theTimer;
@end

@implementation MITBlockTimer
- (id)initWithFireBlock:(MITTimerFireBlock)fireBlock
{
    self = [super init];
    
    if (self) {
        if (fireBlock) {
            self.fireBlock = fireBlock;
        } else {
            self = nil;
        }
    }

    return self;
}


- (void)timerFired:(NSTimer*)theTimer
{
    if (self.fireBlock) {
        if ([NSThread isMainThread]) {
            self.fireBlock();
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.fireBlock();
            });
        }
    }
}
@end


@implementation NSTimer (MITBlockTimer)
+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds
                                    repeats:(BOOL)repeats
                                      fired:(MITTimerFireBlock)firedBlock
{
    MITBlockTimer *blockTimer = [[MITBlockTimer alloc] initWithFireBlock:firedBlock];
    
    if (blockTimer) {
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:seconds
                                                          target:blockTimer
                                                        selector:@selector(timerFired:)
                                                        userInfo:nil
                                                         repeats:repeats];
        
        blockTimer.timer = timer;
        return timer;
    }
    
    return nil;
}

+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)seconds
                           repeats:(BOOL)repeats
                             fired:(MITTimerFireBlock)firedBlock
{
    MITBlockTimer *blockTimer = [[MITBlockTimer alloc] initWithFireBlock:firedBlock];
    
    if (blockTimer) {
        NSTimer *timer = [NSTimer timerWithTimeInterval:seconds
                                                 target:blockTimer
                                               selector:@selector(timerFired:)
                                               userInfo:nil
                                                repeats:repeats];
        
        blockTimer.timer = timer;
        return timer;
    }
    
    return nil;
}

@end