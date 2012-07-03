#import "QRReaderOverlayView.h"
#include <QuartzCore/QuartzCore.h>
@implementation QRReaderOverlayView
@synthesize highlighted = _highlighted;
@synthesize highlightColor = _highlightColor;
@synthesize outlineColor = _outlineColor;
@synthesize overlayColor = _overlayColor;

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
    }
    return self;
}

- (void)dealloc
{
    self.outlineColor = nil;
    self.overlayColor = nil;
    self.highlightColor = nil;
    [super dealloc];
}

- (CGFloat)rotationForInterfaceOrientation:(int)orient
{
    // resolve camera/device image orientation to view/interface orientation
    switch(orient)
    {
        case UIInterfaceOrientationLandscapeLeft:
            return(M_PI_2);
        case UIInterfaceOrientationPortraitUpsideDown:
            return(M_PI);
        case UIInterfaceOrientationLandscapeRight:
            return(3 * M_PI_2);
        case UIInterfaceOrientationPortrait:
            return(2 * M_PI);
    }
    return(0);
}


- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect bds = CGRectZero;
    if (!UIInterfaceOrientationIsLandscape(_interfaceOrientation))
	{
		bds = [self bounds];
	} else {
        CGContextRotateCTM(context,[self rotationForInterfaceOrientation:_interfaceOrientation]);
		bds = CGRectMake(0., 0., [self bounds].size.height, [self bounds].size.width);
	}
    
    CGRect qrRect = [self qrRect];
    
    {
        CGContextBeginPath(context);
        CGContextAddRect(context, bds);
        CGContextAddRect(context, qrRect);
        CGContextClosePath(context);
        
        CGContextSetFillColorWithColor(context, [self.overlayColor CGColor]);
        CGContextEOFillPath(context);
    }
    
    CGColorRef lineColor = (self.highlighted ?
                            [self.highlightColor CGColor] :
                            [self.outlineColor CGColor]);
    
    {
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
    CGSize psize;
    if(UIInterfaceOrientationIsLandscape(_interfaceOrientation)) {
        psize = CGSizeMake(qrRect.size.height, qrRect.size.width);
    } else {
        psize = qrRect.size;
    }
    qrRect.size = psize;
    CGFloat minRect = MIN(qrRect.size.width, qrRect.size.height) * kRectScalingFactor;
    qrRect.origin.x = (qrRect.size.width - minRect) / 2.0;
    qrRect.origin.y = (qrRect.size.height - minRect) / 2.0;
    qrRect.size = CGSizeMake(minRect, minRect);
    
    return qrRect;
}

- (CGRect)normalizedCropRect
{
    CGRect cropRect = [self qrRect];
    CGRect normalizedRect = CGRectZero;
    
    normalizedRect.origin.x = cropRect.origin.x / CGRectGetMaxX(self.bounds);
    normalizedRect.origin.y = cropRect.origin.y / CGRectGetMaxY(self.bounds);
    normalizedRect.size.width = cropRect.size.width / CGRectGetWidth(self.bounds);
    normalizedRect.size.height = cropRect.size.height / CGRectGetHeight(self.bounds);
    
    return normalizedRect;
}

- (void)setHighlightColor:(UIColor *)highlightColor {
    if (![self.highlightColor isEqual:highlightColor]) {
        [self setNeedsDisplay];
    }
    
    [_highlightColor release];
    _highlightColor = [highlightColor retain];
}

- (void)setOutlineColor:(UIColor *)outlineColor {
    if (![self.outlineColor isEqual:outlineColor]) {
        [self setNeedsDisplay];
    }
    
    [_outlineColor release];
    _outlineColor = [outlineColor retain];
}

- (void)setOverlayColor:(UIColor *)overlayColor {
    if (![self.overlayColor isEqual:overlayColor]) {
        [self setNeedsDisplay];
    }
    
    [_overlayColor release];
    _overlayColor = [overlayColor retain];
}

- (void) willRotateToInterfaceOrientation: (UIInterfaceOrientation) orient
                                 duration: (NSTimeInterval) duration {
    if(_interfaceOrientation != orient) {
        _interfaceOrientation = orient;
        _animationDuration = duration;
    }
    [self setNeedsDisplay];
}

@end
