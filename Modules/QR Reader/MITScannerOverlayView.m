#import "MITScannerOverlayView.h"
#include <QuartzCore/QuartzCore.h>

@interface MITScannerOverlayView ()
@property (retain) UILabel *helpLabel;
@end

@implementation MITScannerOverlayView
{
    UIInterfaceOrientation _interfaceOrientation;
}

@synthesize highlighted = _highlighted;
@synthesize highlightColor = _highlightColor;
@synthesize outlineColor = _outlineColor;
@synthesize overlayColor = _overlayColor;
@synthesize helpLabel = _helpLabel;
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
            UILabel *helpLabel = [[[UILabel alloc] init] autorelease];
            helpLabel.backgroundColor = [UIColor clearColor];
            helpLabel.textColor = [UIColor whiteColor];
            helpLabel.textAlignment = UITextAlignmentCenter;
            helpLabel.lineBreakMode = UILineBreakModeWordWrap;
            helpLabel.numberOfLines = 0;
            [self addSubview:helpLabel];
            self.helpLabel = helpLabel;
        }
        
        [self setNeedsLayout];
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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Layout the help text view
    {
        CGRect cropRect = self.qrRect;
        CGRect bounds = self.bounds;
        CGRect textFrame = CGRectZero;
        
        CGFloat maxHeight = cropRect.origin.y - bounds.origin.y;
        CGSize textSize = [self.helpLabel.text sizeWithFont:self.helpLabel.font
                                          constrainedToSize:CGSizeMake(CGRectGetWidth(cropRect), maxHeight)
                                              lineBreakMode:self.helpLabel.lineBreakMode];
        
        textFrame.size.width = textSize.width;
        textFrame.size.height = textSize.height;
        textFrame.origin.y = floor(bounds.origin.y +
                              ((maxHeight - textSize.height) / 2.0));
        textFrame.origin.x = floor(((bounds.size.width - textSize.width) / 2.0));
        self.helpLabel.frame = textFrame;
    }
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
    CGSize boundSize;
    if(UIInterfaceOrientationIsLandscape(_interfaceOrientation)) {
        boundSize = CGSizeMake(qrRect.size.height, qrRect.size.width);
    } else {
        boundSize = qrRect.size;
    }
    qrRect.size = boundSize;
    CGFloat minRect = MIN(qrRect.size.width, qrRect.size.height) * kRectScalingFactor;
    qrRect.origin.x = (qrRect.size.width - minRect) / 2.0;
    qrRect.origin.y = (qrRect.size.height - minRect) / 2.0;
    qrRect.size = CGSizeMake(minRect, minRect);
    
    return qrRect;
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

- (void)setHelpText:(NSString *)helpText
{
    self.helpLabel.text = helpText;
}

- (NSString*)helpText
{
    return self.helpLabel.text;
}

- (void) willRotateToInterfaceOrientation: (UIInterfaceOrientation) orient
                                 duration: (NSTimeInterval) duration {
    [self setNeedsLayout];
}

@end
