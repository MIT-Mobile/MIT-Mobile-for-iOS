#import "MITTapGestureRecognizer.h"

@interface MITTapGestureRecognizer()

@property BOOL moved;

@end

@implementation MITTapGestureRecognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.moved = NO;
    [self highlightCell];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.moved) {
        [self cellSelected];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self unHighlightCell];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.moved = YES;
    [self unHighlightCell];
}

- (void)cellSelected
{
    [self.delegate cellSelected:self];
}

- (void)highlightCell
{
    [self.delegate highlightCell:self];
}

- (void)unHighlightCell
{
    [self.delegate unHighlightCell:self];
}

@end
