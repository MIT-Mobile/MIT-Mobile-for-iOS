#import "MITMapRoute.h"

@implementation MITGenericMapRoute

@synthesize pathLocations, fillColor, strokeColor, lineWidth, lineDashPattern;

- (id)init {
    self = [super init];
    if (self) {
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
    self.lineDashPattern = nil;
    [super dealloc];
}

@end

