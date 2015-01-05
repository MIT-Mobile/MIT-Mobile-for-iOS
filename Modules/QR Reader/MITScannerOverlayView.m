#import "MITScannerOverlayView.h"
#include <QuartzCore/QuartzCore.h>
#import "UIKit+MITAdditions.h"

@interface MITScannerOverlayView ()
@property (weak) UILabel *helpLabel;
@end

@implementation MITScannerOverlayView

@dynamic helpText;

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.highlightColor = [UIColor greenColor];
        self.outlineColor = [UIColor colorWithWhite:0.65
                                              alpha:1.0];
        self.overlayColor = [UIColor colorWithWhite:0.0
                                              alpha:0.5];
        
        {
            UILabel *helpLabel = [[UILabel alloc] initWithFrame:CGRectMake(0., 64., frame.size.width, 100.)];
            helpLabel.backgroundColor = [UIColor clearColor];
            helpLabel.textColor = [UIColor whiteColor];
            helpLabel.textAlignment = NSTextAlignmentCenter;
            helpLabel.lineBreakMode = NSLineBreakByWordWrapping;
            helpLabel.numberOfLines = 0;
            [self addSubview:helpLabel];
            self.helpLabel = helpLabel;
        }
        
        [self setNeedsLayout];
    }
    return self;
}

- (CGFloat)rotationForInterfaceOrientation:(int)orient
{
    // resolve camera/device image orientation to view/interface orientation
    switch(orient)
    {
        case UIInterfaceOrientationLandscapeLeft:
            return M_PI_2;
        case UIInterfaceOrientationPortraitUpsideDown:
            return M_PI;
        case UIInterfaceOrientationLandscapeRight:
            return 3. * M_PI_2;
        case UIInterfaceOrientationPortrait:
            return 2. * M_PI;
    }

    return 0;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Layout the help text view
    {
        CGRect cropRect = self.qrRect;
        CGRect textFrame = self.helpLabel.frame;
        textFrame.size.height = cropRect.origin.y - textFrame.origin.y;
        textFrame.origin.x = 0;
        textFrame.size.width = self.frame.size.width;
        self.helpLabel.frame = textFrame;
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect bounds = [self bounds];
    CGRect qrRect = [self qrRect];
    
    {
        CGContextBeginPath(context);
        CGContextAddRect(context, bounds);
        CGContextAddRect(context, qrRect);
        CGContextClosePath(context);
        
        CGContextSetFillColorWithColor(context, [self.overlayColor CGColor]);
        CGContextEOFillPath(context);
    }
    
    CGColorRef lineColor = (self.highlighted ?
                            [self.highlightColor CGColor] :
                            [self.outlineColor CGColor]);
    
    {
        // TODO: This path doesn't close cleanly.
        //   By using a dashed line instead of 4 separate paths,
        //   the top left corner is not closed completely.
        CGFloat lineWidth = 4.0;
        CGFloat lineOffset = lineWidth / 2.0;
        
        qrRect.origin.x -= lineOffset;
        qrRect.origin.y -= lineOffset;
        qrRect.size.width += lineWidth;
        qrRect.size.height += lineWidth;
        
        CGContextBeginPath(context);
        CGContextMoveToPoint(context,
                             qrRect.origin.x,
                             qrRect.origin.y);
        CGContextAddLineToPoint(context,
                                qrRect.origin.x + qrRect.size.width,
                                qrRect.origin.y);
        CGContextAddLineToPoint(context,
                                qrRect.origin.x + qrRect.size.width,
                                qrRect.origin.y + qrRect.size.height);
        CGContextAddLineToPoint(context,
                                qrRect.origin.x,
                                qrRect.origin.y + qrRect.size.height);
        CGContextClosePath(context);
        
        CGFloat unit = (qrRect.size.width / 4.0);
        CGFloat length = {unit * 2.0};
        CGContextSetLineDash(context,
                             unit,
                             &length,
                             1);
        CGContextSetLineWidth(context, lineWidth);
        CGContextSetStrokeColorWithColor(context, lineColor);
        
        CGContextDrawPath(context, kCGPathStroke);
    }
}

#pragma mark -
#pragma mark Mutators
- (void)setHighlighted:(BOOL)highlighted {
    if (_highlighted != highlighted) {
        [self setNeedsDisplay];
    }
    
    _highlighted = highlighted;
}

- (CGRect)qrRect {
    static CGFloat kRectScalingFactor = 0.75;

    CGRect qrRect = self.bounds;
    CGFloat minRect = MIN(qrRect.size.width, qrRect.size.height) * kRectScalingFactor;
    qrRect.origin.x = (qrRect.size.width - minRect) / 2.0;
    qrRect.origin.y = (qrRect.size.height - minRect) / 2.0 + 44.;
    qrRect.size = CGSizeMake(minRect, minRect);
    
    return qrRect;
}

- (void)setHighlightColor:(UIColor *)highlightColor {
    if (![self.highlightColor isEqual:highlightColor]) {
        [self setNeedsDisplay];
    }

    _highlightColor = highlightColor;
}

- (void)setOutlineColor:(UIColor *)outlineColor {
    if (![self.outlineColor isEqual:outlineColor]) {
        [self setNeedsDisplay];
    }

    _outlineColor = outlineColor;
}

- (void)setOverlayColor:(UIColor *)overlayColor {
    if (![self.overlayColor isEqual:overlayColor]) {
        [self setNeedsDisplay];
    }

    _overlayColor = overlayColor;
}

- (void)setHelpText:(NSString *)helpText
{
    self.helpLabel.text = helpText;
}

- (NSString*)helpText
{
    return self.helpLabel.text;
}

@end
