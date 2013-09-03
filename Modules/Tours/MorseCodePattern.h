#import <Foundation/Foundation.h>


@interface MorseCodePattern : NSObject {
    NSMutableArray *_lineDashPattern;
}

- (NSArray *)lineDashPattern;
- (MorseCodePattern *)dash;
- (MorseCodePattern *)dot;
- (MorseCodePattern *)pause;


@end
