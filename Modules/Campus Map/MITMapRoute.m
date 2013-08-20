#import "MITMapRoute.h"

@implementation MITGenericMapRoute
- (id)init {
    self = [super init];
    if (self) {
        // TODO: define default fill/stroke colors in config
        _fillColor = [UIColor redColor];
        _strokeColor = [UIColor redColor];
        _lineWidth = 3;
    }

    return self;
}

@end
