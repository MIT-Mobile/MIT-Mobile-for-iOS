
#import "MITLoadingActivityView.h"

@interface MITLoadingActivityView ()
@property (nonatomic,retain) UIImageView *backgroundImage;
@property (nonatomic,retain) UIView *activityView;
@end

@implementation MITLoadingActivityView

@synthesize backgroundImage = _backgroundImage;
@synthesize activityView = _activityView;
@dynamic usesBackgroundImage;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self layoutSubviews];
    }
    return self;
}

- (void)layoutSubviews {
    {
        if (self.backgroundImage == nil) {
            UIImageView *imageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageNameBackground]] autorelease];
            [self addSubview:imageView];
            self.backgroundImage = imageView;
        }

        self.backgroundImage.frame = self.bounds;
    }
    
    {
        if (self.activityView == nil) {
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
            
            viewFrame.origin.x = (self.bounds.size.width - viewFrame.size.width) / 2.0;
            viewFrame.origin.y = (self.bounds.size.height - viewFrame.size.height) / 2.0;
            
            activityView.frame = CGRectIntegral(viewFrame);
            self.activityView.autoresizingMask = UIViewAutoresizingNone;

            [activityView addSubview:spinner];
            [activityView addSubview:loadingLabel];
            
            [spinner startAnimating];
            [self addSubview:activityView];
            self.activityView = activityView;
        }
        
    }
}

- (void)dealloc {
    self.backgroundImage = nil;
    self.activityView = nil;
    
    [super dealloc];
}

- (void)setUsesBackgroundImage:(BOOL)usesBackgroundImage
{
    BOOL current = !(self.backgroundImage.hidden);
    
    if (usesBackgroundImage != current)
    {
        [self setNeedsDisplay];
    }
    
    self.backgroundImage.hidden = !(usesBackgroundImage);
}

- (BOOL)usesBackgroundImage
{
    return (self.backgroundImage.hidden == NO);
}


@end
