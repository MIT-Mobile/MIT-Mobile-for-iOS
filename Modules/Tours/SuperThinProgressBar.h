#import <UIKit/UIKit.h>

// this comment is here to remind me that this is a low priority feature.

@interface SuperThinProgressBar : UIView

@property (nonatomic, assign) NSUInteger numberOfSegments;
@property (nonatomic, assign) NSUInteger currentPosition;

@property (nonatomic, assign) BOOL vertical;

- (void)markAsDone;

@end
