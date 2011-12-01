#import "MITLoadingActivityView.h"

@interface MITLoadingActivityView ()
@property (nonatomic,retain) UIView *activityView;
@end

@implementation MITLoadingActivityView

@synthesize activityView = _activityView;
@synthesize usesBackgroundImage = _usesBackgroundImage;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.usesBackgroundImage = YES;
        
        UIView *activityView = [[[UIView alloc] init] autorelease];
        UILabel *loadingLabel = [[[UILabel alloc] init] autorelease];
        UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
        
        NSString *loadingText = @"Loading...";
        
        CGSize labelSize = [loadingText sizeWithFont:loadingLabel.font];
        CGFloat labelLeftMargin = 5.0;
        loadingLabel.frame = CGRectMake(spinner.frame.size.width + labelLeftMargin,
                                        0.0,
                                        labelSize.width,
                                        labelSize.height);
        loadingLabel.backgroundColor = [UIColor clearColor];
        loadingLabel.text = loadingText;
        
        CGRect viewFrame = CGRectMake(0.0,
                                      0.0,
                                      labelSize.width + spinner.frame.size.width + labelLeftMargin,
                                      labelSize.height);
        
        activityView.frame = viewFrame;
        activityView.autoresizingMask = UIViewAutoresizingNone;
        
        [activityView addSubview:spinner];
        [activityView addSubview:loadingLabel];
        
        [spinner startAnimating];
        [self addSubview:activityView];
        self.activityView = activityView;
    }
    return self;
}

- (void)layoutSubviews {
    // center the loading indicator
    CGRect frame = self.activityView.frame;
    frame.origin.x = (self.bounds.size.width - frame.size.width) / 2.0;
    frame.origin.y = (self.bounds.size.height - frame.size.height) / 2.0;
    // make sure it is always whole pixel aligned
    self.activityView.frame = CGRectIntegral(frame);
}

- (void)dealloc {
    self.activityView = nil;
    
    [super dealloc];
}

- (void)setUsesBackgroundImage:(BOOL)usesBackgroundImage
{
    if (usesBackgroundImage != self.usesBackgroundImage) {
        _usesBackgroundImage = usesBackgroundImage;
        if (self.usesBackgroundImage) {
            self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
        } else {
            self.backgroundColor = [UIColor clearColor];
        }
        [self setNeedsDisplay];
    }
}

@end
