#import "MITMapDelegateInterceptor.h"

@implementation MITMapDelegateInterceptor

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([self.middleManDelegate respondsToSelector:aSelector]) {
        return self.middleManDelegate;
    }
    if ([self.endOfLineDelegate respondsToSelector:aSelector]) {
        return self.endOfLineDelegate;
    }
    return [super forwardingTargetForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([self.middleManDelegate respondsToSelector:aSelector] ||
        [self.endOfLineDelegate respondsToSelector:aSelector]) {
        return YES;
    }
    return [super respondsToSelector:aSelector];
}

@end