#import "MITAttributedLabel.h"
#import "NSMutableAttributedString+MITAdditions.h"

@interface MITAttributedLabel ()
@property (nonatomic, strong) NSMutableAttributedString *visibleAttributedString;
@property (nonatomic, assign) CTFramesetterRef framesetter;

- (NSSet *)invalidatingKeyPaths;

- (void)invalidateCache;
@end

@implementation MITAttributedLabel
{
    NSAttributedString *_attributedString;
    NSMutableAttributedString *_visibleAttributedString;
    CTFramesetterRef _framesetter;
}

@dynamic attributedString;
@dynamic framesetter;
@dynamic visibleAttributedString;

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.visibleAttributedString = [[[NSMutableAttributedString alloc] init] autorelease];

        [[self invalidatingKeyPaths] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            [self addObserver:self
                   forKeyPath:(NSString *)obj
                      options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                      context:nil];
        }];
    }

    return self;
}

- (void)dealloc
{
    [[self invalidatingKeyPaths] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [self removeObserver:self
                  forKeyPath:(NSString *)obj];
    }];

    self.visibleAttributedString = nil;
    self.attributedString = nil;
    self.framesetter = nil;
    [super dealloc];
}

#pragma mark - Overridden methods
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSSet *keys = [self invalidatingKeyPaths];
    if ([keys containsObject:keyPath])
    {
        id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
        id newValue = [change objectForKey:NSKeyValueChangeNewKey];

        if ([oldValue isEqual:newValue] == NO)
        {
            [self invalidateCache];
        }
    }
}

- (void)setText:(NSString *)aText
{
    if (aText)
    {
        self.attributedString = [[[NSAttributedString alloc] initWithString:aText] autorelease];
    }
    else
    {
        self.attributedString = nil;
    }
}

- (void)drawTextInRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0f, -1.0f);

    CGSize fitSize = [self sizeThatFits:rect.size];

    CGRect stringRect = CGRectZero;
    stringRect.size.height = ceilf(fitSize.height);
    stringRect.size.width = ceilf(fitSize.width);
    stringRect.origin.y = ceilf((rect.size.height - fitSize.height) / 2.0);
    stringRect.origin.x = rect.origin.x;


    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectStandardize(stringRect));
    CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter,
                                                CFRangeMake(0, 0),
                                                path,
            NULL);
    CGPathRelease(path);

    CTFrameDraw(frame, context);
    CFRelease(frame);
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CTFramesetterRef framesetter = self.framesetter;
    CGSize fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,
                                                                  CFRangeMake(0, 0),
            NULL,
                                                                  CGSizeMake(size.width, CGFLOAT_MAX),
            NULL);

    fitSize.width = (CGFloat)ceil(fitSize.width);
    fitSize.height = (CGFloat)ceil(fitSize.height);

    return fitSize;
}


#pragma mark - Dynamic Properties
- (NSAttributedString *)attributedString
{
    return _attributedString;
}

- (void)setAttributedString:(NSAttributedString *)anAttributedString
{
    if ([anAttributedString isEqualToAttributedString:_attributedString] == NO)
    {
        [self willChangeValueForKey:@"attributedString"];
        [_attributedString release];
        _attributedString = [anAttributedString retain];
        [self didChangeValueForKey:@"attributedString"];
    }
}

- (CTFramesetterRef)framesetter
{
    if (_framesetter == NULL)
    {
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.visibleAttributedString);
        self.framesetter = framesetter;
        CFRelease(framesetter);
    }

    return _framesetter;
}

- (void)setFramesetter:(CTFramesetterRef)aFramesetter
{
    if (_framesetter)
    {
        CFRelease(_framesetter);
        _framesetter = nil;
    }

    if (aFramesetter)
    {
        _framesetter = CFRetain(aFramesetter);
    }
}

- (NSMutableAttributedString *)visibleAttributedString
{
    if (_visibleAttributedString == nil)
    {
        NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithAttributedString:self.attributedString] autorelease];

        [attributedString setLineBreakStyle:self.lineBreakMode
                              textAlignment:self.textAlignment
                                   forRange:NSMakeRange(0, [attributedString length])];

        if (self.isHighlighted)
        {
            [attributedString setForegroundColor:self.highlightedTextColor
                                        forRange:NSMakeRange(0, [attributedString length])];
        }

        self.visibleAttributedString = attributedString;
    }

    return _visibleAttributedString;
}

- (void)setVisibleAttributedString:(NSMutableAttributedString *)aVisibleAttributedString
{
    if ([aVisibleAttributedString isEqualToAttributedString:_visibleAttributedString] == NO)
    {
        [_visibleAttributedString release];
        _visibleAttributedString = (aVisibleAttributedString ?
                                    [[NSMutableAttributedString alloc] initWithAttributedString:aVisibleAttributedString] :
                                    nil);
        self.framesetter = nil;
        [self setNeedsDisplay];
    }
}

#pragma mark - Private Methods
- (NSSet *)invalidatingKeyPaths
{
    return [NSSet setWithObjects:@"lineBreakMode",
                                 @"highlightedTextColor",
                                 @"font",
                                 @"textColor",
                                 @"textAlignment",
                                 @"enabled",
                                 @"highlighted",
                                 @"attributedString",
                                 @"text", nil];
}

- (void)invalidateCache
{
    self.visibleAttributedString = nil;
}
@end
