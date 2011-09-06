#import <QuartzCore/QuartzCore.h>
#import "MITSegmentControl.h"

static NSString* const kMITSegmentTitleKey = @"MITSegmentTitle";
static NSString* const kMITSegmentTitleColorKey = @"MITSegmentTitleColor";
static NSString* const kMITSegmentBackgroundColorKey = @"MITSegmentBackgroundColor";

@interface MITSegmentControl ()
@property (nonatomic,retain) NSMutableDictionary *stateDictionary;
@property (nonatomic,retain) UILabel *textLabel;
- (void)internalInit;

- (void)setObject:(id)object forState:(UIControlState)state ofType:(NSString*)typeKey;
- (id)objectForState:(UIControlState)state ofType:(NSString*)typeKey;
@end


@implementation MITSegmentControl
@synthesize textLabel = _textLabel,
            selected = _selected,
            titleInset = _titleInset;

@dynamic shadowColor, shadowOffset, titleFont;

@synthesize stateDictionary = _stateDictionary;

- (id)initWithTabBarItem:(UITabBarItem *)item
{
    self = [super init];
    if (self) {
        [self internalInit];
        
        [self setTitle:item.title
              forState:UIControlStateNormal];
        self.tag = item.tag;
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self internalInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self internalInit];
    }
    
    return self;
}

- (void)dealloc
{
    self.textLabel = nil;
    [super dealloc];
}

- (void)internalInit
{
    self.backgroundColor = [UIColor clearColor];
    
    {
        self.textLabel = [[[UILabel alloc] init] autorelease];
        self.textLabel.textAlignment = UITextAlignmentCenter;
        self.textLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
        self.textLabel.numberOfLines = 1;
        
        self.shadowColor = [UIColor blackColor];
        self.shadowOffset = CGSizeMake(0, -1.0);
        self.titleFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
    }
    
    self.titleInset = CGSizeMake(5.0, 5.0);
    
    self.stateDictionary = [NSMutableDictionary dictionary];
    [self setTitleColor:[UIColor whiteColor]
               forState:UIControlStateNormal];
    [self setBackgroundColor:[UIColor grayColor]
                    forState:UIControlStateNormal];
    
    [self setBackgroundColor:[UIColor colorWithRed:0.6
                                             green:0.2
                                              blue:0.2
                                             alpha:1.0]
                    forState:UIControlStateSelected];
    
    [self setTitleColor:[UIColor lightTextColor]
               forState:UIControlStateDisabled];
    [self setBackgroundColor:[UIColor darkGrayColor]
                    forState:UIControlStateDisabled];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    

    CGPathRef strokeRect = [[UIBezierPath bezierPathWithRoundedRect:rect
                                                      cornerRadius:2] CGPath];
    CGContextAddPath(context, strokeRect);
    CGContextClip(context);
    
    CGContextSaveGState(context);
    
    CGFloat strokeComponents[4] = {    
        0.55, 1,
        0.40, 1
    };
    
    if(self.isSelected) {
        strokeComponents[0]-=0.1;
        strokeComponents[2]-=0.1;
    }
    
    CGGradientRef strokeGradient = CGGradientCreateWithColorComponents(colorSpace, strokeComponents, NULL, 2);	
    CGContextDrawLinearGradient(context, strokeGradient, CGPointMake(0,0), CGPointMake(0,CGRectGetHeight(rect)), 0);
    CGGradientRelease(strokeGradient);
    
    
    // FILL GRADIENT
    
    CGPathRef fillRect = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, 1, 1) cornerRadius:1].CGPath;
    CGContextAddPath(context, fillRect);
    CGContextClip(context);
    
    CGFloat fillComponents[4] = {    
        0.5, 1,
        0.35, 1
    };
    
    if(self.isSelected) {
        fillComponents[0]-=0.1;
        fillComponents[2]-=0.1;
    }
    
    CGGradientRef fillGradient = CGGradientCreateWithColorComponents(colorSpace, fillComponents, NULL, 2);	
    CGContextDrawLinearGradient(context, fillGradient, CGPointMake(0,0), CGPointMake(0,CGRectGetHeight(rect)), 0);
    CGGradientRelease(fillGradient);
    
    CGColorSpaceRelease(colorSpace);
    
    CGContextRestoreGState(context);
    [[self backgroundColorForState:self.state] set];
    UIRectFillUsingBlendMode(rect, kCGBlendModeOverlay);
    
    NSString *title = [self titleForState:self.state];
    if ([title length] > 0) {
        self.textLabel.text = title;
        self.textLabel.textColor = [self titleColorForState:self.state];
        [self.textLabel drawTextInRect:CGRectInset(self.bounds, self.titleInset.width, self.titleInset.height)];
    }
}

#pragma mark - Dynamic Mutators/Accessors
- (void)setShadowOffset:(CGSize)shadowOffset
{
    self.textLabel.shadowOffset = shadowOffset;
}

- (CGSize)shadowOffset
{
    return self.textLabel.shadowOffset;
}

- (void)setShadowColor:(UIColor *)shadowColor
{
    self.textLabel.shadowColor = shadowColor;
}

- (UIColor*)shadowColor
{
    return self.textLabel.shadowColor;
}

- (void)setTitleFont:(UIFont *)titleFont
{
    self.textLabel.font = titleFont;
}

- (UIFont*)titleFont
{
    return self.textLabel.font;
}


#pragma mark - State-based methods
- (void)setObject:(id)object forState:(UIControlState)state ofType:(NSString*)typeKey
{
    NSMutableDictionary *objects = [self.stateDictionary objectForKey:typeKey];
    if (objects == nil) {
        objects = [NSMutableDictionary dictionary];
        [self.stateDictionary setObject:objects
                                 forKey:typeKey];
    }
    
    NSNumber *stateKey = [NSNumber numberWithUnsignedInteger:state];
    [objects setObject:object
                forKey:stateKey];
}

- (id)objectForState:(UIControlState)state ofType:(NSString*)typeKey
{
    NSMutableDictionary *objects = [self.stateDictionary objectForKey:typeKey];
    id obj = nil;
    
    if (objects) {
        NSNumber *stateKey = [NSNumber numberWithUnsignedInteger:state];
        obj = [objects objectForKey:stateKey];
        
        if (obj == nil) {
            stateKey = [NSNumber numberWithUnsignedInteger:UIControlStateNormal];
            obj = [objects objectForKey:stateKey];
        }
    }
    
    return obj;
}

- (void)setTitle:(NSString*)title forState:(UIControlState)state
{
    [self setObject:title
           forState:state
             ofType:kMITSegmentTitleKey];
}

- (NSString*)titleForState:(UIControlState)state;
{
    return (NSString*)[self objectForState:state
                                    ofType:kMITSegmentTitleKey];
}


- (void)setTitleColor:(UIColor*)titleColor forState:(UIControlState)state
{
    [self setObject:titleColor
           forState:state
             ofType:kMITSegmentTitleColorKey];
}

- (UIColor*)titleColorForState:(UIControlState)state
{
    return (UIColor*)[self objectForState:state
                                   ofType:kMITSegmentTitleColorKey];
}


- (void)setBackgroundColor:(UIColor *)backgroundColor forState:(UIControlState)state
{
    [self setObject:backgroundColor
           forState:state
             ofType:kMITSegmentBackgroundColorKey];
}

- (UIColor*)backgroundColorForState:(UIControlState)state
{
    return (UIColor*)[self objectForState:state
                                   ofType:kMITSegmentBackgroundColorKey];
}

@end
