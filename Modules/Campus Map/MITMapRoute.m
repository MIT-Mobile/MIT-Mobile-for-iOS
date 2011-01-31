#import "MITMapRoute.h"

@implementation MITGenericMapRoute

@synthesize pathLocations, fillColor, strokeColor, lineWidth;

- (id)init {
    if (self = [super init]) {
        // TODO: define default fill/stroke colors in config
        self.fillColor = [UIColor redColor];
        self.strokeColor = [UIColor redColor];
        self.lineWidth = 3;
    }
    return self;
}

- (void)dealloc {
    self.pathLocations = nil;
    self.fillColor = nil;
    self.strokeColor = nil;
    [super dealloc];
}

@end

