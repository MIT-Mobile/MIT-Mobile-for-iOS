#import "MITNavigationActivityView.h"

@interface MITNavigationActivityView ()
@property (nonatomic, retain) UIActivityIndicatorView *activityView;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) UILabel *titleView;
@end

@implementation MITNavigationActivityView
@synthesize activityView = _activityView;
@synthesize titleView = _titleView;

@dynamic title;

- (id)initWithFrame:(CGRect)frame
{
    return [self init];
}

- (id)init
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        UIColor *textColor = [UIColor blackColor];
        UIActivityIndicatorViewStyle indicatorStyle = UIActivityIndicatorViewStyleGray;
        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
            textColor = [UIColor whiteColor];
            indicatorStyle = UIActivityIndicatorViewStyleWhite;
        }
        
        self.titleView = [[UILabel alloc] init];
        self.titleView.backgroundColor = [UIColor clearColor];
        self.titleView.textAlignment = NSTextAlignmentCenter;
        self.titleView.textColor = textColor;
        self.titleView.font = [UIFont boldSystemFontOfSize:20.0];
        self.titleView.adjustsFontSizeToFitWidth=YES;
        self.titleView.minimumScaleFactor = 0.75;
        self.titleView.lineBreakMode = NSLineBreakByTruncatingTail;
        self.titleView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin);
        self.titleView.numberOfLines = 1;
        [self addSubview:self.titleView];
        
        
        self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:indicatorStyle];
        self.activityView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.activityView];
    }

    return self;
}

- (void)dealloc
{
    self.activityView = nil;
    self.titleView = nil;
}

#pragma mark - View Management
- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    CGPoint origin = bounds.origin;
    
    {
        CGRect activityFrame = self.activityView.frame;
        activityFrame.origin = CGPointMake(origin.x,
                                           origin.y + ((CGRectGetHeight(bounds) - CGRectGetHeight(activityFrame)) / 2.0));

        origin.x = CGRectGetMaxX(activityFrame) + 5.0;
        self.activityView.frame = activityFrame;
        
    }

    {
        CGSize labelSize = [self.title sizeWithFont:self.titleView.font];
        CGRect labelFrame = CGRectMake(origin.x,
                                       origin.y + ((CGRectGetHeight(bounds) - labelSize.height) / 2.0),
                                       labelSize.width,
                                       labelSize.height);
        self.titleView.frame = labelFrame;
    }
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize minSize = [self.title sizeWithFont:self.titleView.font];
    minSize.width += CGRectGetWidth(self.activityView.frame);
    minSize.height = MAX(minSize.height, CGRectGetHeight(self.activityView.frame));

    return CGSizeMake(minSize.width, minSize.height);
}

#pragma mark - Public Methods
- (void)startActivityWithTitle:(NSString *)title
{
    self.title = title;
    [self.activityView startAnimating];
}

- (void)stopActivity
{
    [self.activityView stopAnimating];
}

#pragma mark - Dynamic Properties
- (void)setTitle:(NSString *)title
{
    self.titleView.text = title;
    [self sizeToFit];
    [self setNeedsLayout];
}

- (NSString *)title
{
    return self.titleView.text;
}

@end
