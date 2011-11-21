#import "MorseCodePattern.h"
#define PAUSE 4


@implementation MorseCodePattern

- (id)init {
    self = [super init];
    if(self) {
        lineDashPattern = [NSMutableArray new];
    }
    return self;
}

- (MorseCodePattern *)dash {
    [lineDashPattern addObjectsFromArray:[NSArray arrayWithObjects:[NSNumber numberWithInt:6], [NSNumber numberWithInt:PAUSE], nil]];
    return self;
}
    
- (MorseCodePattern *)dot {
    [lineDashPattern addObjectsFromArray:[NSArray arrayWithObjects:[NSNumber numberWithInt:0], [NSNumber numberWithInt:PAUSE], nil]];
    return self;
}

- (MorseCodePattern *)pause {
    NSInteger lastGap = [(NSNumber *)[lineDashPattern lastObject] intValue];
    lastGap += PAUSE;
    [lineDashPattern replaceObjectAtIndex:([lineDashPattern count] - 1) withObject:[NSNumber numberWithInt:lastGap]];
    return self;
}
     
- (NSArray *)lineDashPattern {
    return lineDashPattern;
}

- (void)dealloc {
    [lineDashPattern release];
    [super dealloc];
}

@end
