#include "MITBlockTimer.h"

@interface MITBlockTimer ()
@property (nonatomic,weak) NSTimer *timer;
@property (nonatomic,copy) MITTimerFireBlock fireBlock;

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
        self.fireBlock(theTimer);
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
                                                          target:self
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
                                                 target:self
                                               selector:@selector(timerFired:)
                                               userInfo:nil
                                                repeats:repeats];
        
        blockTimer.timer = timer;
        return timer;
    }
    
    return nil;
}

@end