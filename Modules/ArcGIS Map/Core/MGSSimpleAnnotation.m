#import "MGSSimpleAnnotation.h"

@implementation MGSSimpleAnnotation

- (id)init {
    self = [super init];
    
    if (self) {
        self.markerOptions = MGSMarkerOptionsMake(CGPointMake(0.0, 0.0), CGPointMake(0.0, 0.0));
    }
    
    return self;
}

@end
