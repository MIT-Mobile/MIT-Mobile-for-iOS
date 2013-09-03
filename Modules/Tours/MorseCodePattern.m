#import "MorseCodePattern.h"
#define PAUSE 4


@implementation MorseCodePattern

- (id)init {
    self = [super init];
    if(self) {
        _lineDashPattern = [NSMutableArray new];
    }
    return self;
}

- (MorseCodePattern *)dash {
    [_lineDashPattern addObjectsFromArray:[NSArray arrayWithObjects:[NSNumber numberWithInt:6], [NSNumber numberWithInt:PAUSE], nil]];
    return self;
}
    
- (MorseCodePattern *)dot {
    [_lineDashPattern addObjectsFromArray:[NSArray arrayWithObjects:[NSNumber numberWithInt:0], [NSNumber numberWithInt:PAUSE], nil]];
    return self;
}

- (MorseCodePattern *)pause {
    NSInteger lastGap = [(NSNumber *)[_lineDashPattern lastObject] intValue];
    lastGap += PAUSE;
    [_lineDashPattern replaceObjectAtIndex:([_lineDashPattern count] - 1) withObject:[NSNumber numberWithInt:lastGap]];
    return self;
}
     
- (NSArray *)lineDashPattern {
    return _lineDashPattern;
}

@end
