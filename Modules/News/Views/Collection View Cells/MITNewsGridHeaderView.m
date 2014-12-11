#import "MITNewsGridHeaderView.h"

@implementation MITNewsGridHeaderView

- (UIView*)highlightedBackgroundView
{
    if (!_highlightedBackgroundView) {
        UIView *highlightedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
        highlightedBackgroundView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        highlightedBackgroundView.backgroundColor = [UIColor colorWithRed:217.0/255.0 green:217.0/255.0 blue:217.0/255.0 alpha:1];
        
        [self insertSubview:highlightedBackgroundView atIndex:0];
        _highlightedBackgroundView = highlightedBackgroundView;
    }
    
    return _highlightedBackgroundView;
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (_highlighted != highlighted) {
        _highlighted = highlighted;
        
        self.highlightedBackgroundView.hidden = !_highlighted;
        self.headerLabel.highlighted = _highlighted;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    self.highlighted = YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    self.highlighted = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    self.highlighted = NO;
}

@end
