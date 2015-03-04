#import "KIFUITestActor+Util.h"

@implementation KIFUITestActor (Util)
- (void)pressReturnKeyOnCurrentFirstResponder {
    [self enterTextIntoCurrentFirstResponder:@"\n"];
}
@end
