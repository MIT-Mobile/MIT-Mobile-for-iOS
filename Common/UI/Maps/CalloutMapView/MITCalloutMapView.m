#import "MITCalloutMapView.h"
#import "MITCalloutView.h"

@interface MKMapView (UIGestureRecognizer)

// this tells the compiler that MKMapView actually implements this method
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;

@end

@implementation MITCalloutMapView

// override UIGestureRecognizer's delegate method so we can prevent MKMapView's recognizer from firing
// when we interact with UIControl subclasses inside our callout view.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([self hasCalloutParentView:touch.view]) {
        return NO;
    } else {
        return [super gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
    }
}

- (BOOL)hasCalloutParentView:(UIView *)view
{
    if (view == nil || [view isKindOfClass:[MITCalloutMapView class]]) {
        return false;
    }
    else if ([view isKindOfClass:[SMCalloutView class]]) {
        return true;
    } else if ([view isKindOfClass:[MITCalloutView class]]) {
        return true;
    }
    else {
        return [self hasCalloutParentView:view.superview];
    }
}

// Allow touches to be sent to our calloutview.
// See this for some discussion of why we need to override this: https://github.com/nfarina/calloutview/pull/9
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *smcalloutMaybe = [self.calloutView hitTest:[self.calloutView convertPoint:point fromView:self] withEvent:event];
    if (smcalloutMaybe) {
        return smcalloutMaybe;
    }
    UIView *mitcalloutMaybe = [self.mitCalloutView hitTest:[self.mitCalloutView convertPoint:point fromView:self] withEvent:event];
    if (mitcalloutMaybe) {
        return mitcalloutMaybe;
    }
    return [super hitTest:point withEvent:event];
}

@end
